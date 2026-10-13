import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'hlc.dart';
import 'binary_protocol.dart';
import 'crdt.dart';
import 'lan_transport.dart';

typedef EntityDecoder<T> = T Function(Uint8List payload);
typedef EntityEncoder<T> = Uint8List Function(T entity);
typedef SyncEntityHandler = void Function(
  int objectId,
  SyncOpCode opCode,
  Uint8List payload,
  HlcTimestamp hlc,
);

/// Main facade for FreeBoxSync.
///
/// Easily synchronizes ObjectBox databases across local devices over Wi-Fi/Ethernet/Bus
/// without a central server.
class FreeBoxSync {
  static final FreeBoxSync _instance = FreeBoxSync._internal();
  static FreeBoxSync get instance => _instance;

  FreeBoxSync._internal();

  dynamic _store;
  String? _nodeId;
  String _stationName = 'Poste Caisse';
  HybridLogicalClock? _clock;
  LanTransport? _transport;
  int _txSequence = 0;
  bool _isApplyingRemoteUpdate = false;
  Timer? _heartbeatTimer;

  final Map<String, DateTime> _activePeers = {};
  final StreamController<int> _peerCountController = StreamController<int>.broadcast();
  final StreamController<String> _syncLogsController = StreamController<String>.broadcast();
  final List<String> _recentLogs = [];
  final Map<int, SyncEntityHandler> _entityHandlers = {};

  Stream<int> get peerCountStream => _peerCountController.stream;
  Stream<String> get syncLogsStream => _syncLogsController.stream;
  List<String> get recentLogs => List.unmodifiable(_recentLogs);
  int get peerCount => _activePeers.length;
  String get nodeId => _nodeId ?? 'non_initialise';
  String get stationName => _stationName;
  HybridLogicalClock? get clock => _clock;

  bool get isInitialized => _store != null;

  void setStationName(String name) {
    _stationName = name;
    sendHeartbeat();
  }

  /// Registers a handler for remote entity mutations arriving from peers.
  void registerEntityHandler(int entityId, SyncEntityHandler handler) {
    _entityHandlers[entityId] = handler;
  }

  /// Initializes the decentralized LAN sync engine.
  Future<void> initialize({
    required dynamic store,
    String? nodeId,
    String? stationName,
    int discoveryPort = 8443,
    int tcpPort = 8444,
  }) async {
    _store = store;
    _nodeId = nodeId ?? 'caisse_${Random().nextInt(999999).toString().padLeft(6, '0')}';
    if (stationName != null) _stationName = stationName;
    _clock = HybridLogicalClock(nodeId: _nodeId!);

    _transport = createLanTransport(
      nodeId: _nodeId!,
      discoveryPort: discoveryPort,
      tcpPort: tcpPort,
      onFrameReceived: _handleIncomingFrame,
    );


    await _transport!.start();
    _log('Moteur P2P FreeBoxSync démarré sur nœud: $_nodeId');

    // Heartbeat périodique pour la découverte mutuelle des postes
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      sendHeartbeat();
      _purgeInactivePeers();
    });

    sendHeartbeat();
  }

  /// Diffuse un message de présence sur le réseau local
  void sendHeartbeat() {
    if (!isInitialized || _isApplyingRemoteUpdate) return;
    final hlc = _clock!.now();
    final payload = utf8.encode(jsonEncode({
      'station': _stationName,
      'nodeId': _nodeId,
      'time': DateTime.now().toIso8601String(),
    }));

    final frame = encodeSyncFrame(
      txId: ++_txSequence,
      hlc: hlc,
      opCode: SyncOpCode.ping,
      entityId: 0,
      objectId: 0,
      deltaMask: 0,
      payload: Uint8List.fromList(payload),
    );

    _transport?.broadcastBinaryFrame(frame);
  }

  /// Diffuse une entité au format JSON vers tous les postes pairs du réseau local.
  void broadcastEntityJson(
    int entityId,
    int objectId,
    Map<String, dynamic> data, {
    SyncOpCode opCode = SyncOpCode.putObject,
  }) {
    if (!isInitialized || _isApplyingRemoteUpdate) return;

    final jsonStr = jsonEncode(data);
    final payload = Uint8List.fromList(utf8.encode(jsonStr));

    broadcastMutation(
      entityId: entityId,
      objectId: objectId,
      deltaMask: 1,
      payload: payload,
      opCode: opCode,
    );

    _log('Emission P2P -> Entité #$entityId (ID: $objectId, ${payload.length} o)');
  }

  /// Broadcasts a locally mutated object to all peers on the local LAN.
  void broadcastMutation({
    required int entityId,
    required int objectId,
    required int deltaMask,
    required Uint8List payload,
    SyncOpCode opCode = SyncOpCode.putObject,
  }) {
    if (!isInitialized || _isApplyingRemoteUpdate) return;

    _txSequence++;
    final hlc = _clock!.now();

    final frameBytes = encodeSyncFrame(
      txId: _txSequence,
      hlc: hlc,
      opCode: opCode,
      entityId: entityId,
      objectId: objectId,
      deltaMask: deltaMask,
      payload: payload,
    );

    _transport?.broadcastBinaryFrame(frameBytes);
  }

  /// Internal handler for frames arriving over the local network.
  void _handleIncomingFrame(Uint8List rawBytes, String peerIp) {
    if (rawBytes.length < headerSize) return;

    try {
      final frame = decodeSyncFrame(rawBytes);

      final senderNodeId = frame.header.hlc.nodeId;
      if (senderNodeId == _nodeId) return; // Ignore own echoes

      // Enregistre ou met à jour le poste pair
      final isNewPeer = !_activePeers.containsKey(senderNodeId);
      _activePeers[senderNodeId] = DateTime.now();
      _peerCountController.add(_activePeers.length);

      if (isNewPeer) {
        _log('Nouveau poste pair détecté: $senderNodeId ($peerIp)');
      }

      // Advance local Hybrid Logical Clock
      _clock?.receive(frame.header.hlc);

      // Traitement selon l'opCode
      if (frame.header.opCode == SyncOpCode.ping) {
        // Simple heartbeat
        return;
      }

      // Traitement des mutations reçues
      final entityId = frame.header.entityId;
      final objectId = frame.header.objectId;
      final handler = _entityHandlers[entityId];

      if (handler != null) {
        _log('Réception P2P <- Entité #$entityId (ID: $objectId de $senderNodeId)');
        runWithoutSyncEcho(() {
          handler(objectId, frame.header.opCode, frame.payload, frame.header.hlc);
        });
      }
    } catch (e) {
      _log('Erreur décodage trame P2P: $e');
    }
  }

  void _purgeInactivePeers() {
    final now = DateTime.now();
    final toRemove = <String>[];
    _activePeers.forEach((id, lastSeen) {
      if (now.difference(lastSeen).inSeconds > 20) {
        toRemove.add(id);
      }
    });

    if (toRemove.isNotEmpty) {
      for (final id in toRemove) {
        _activePeers.remove(id);
        _log('Poste pair déconnecté: $id');
      }
      _peerCountController.add(_activePeers.length);
    }
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final formatted = '[$timestamp] $message';
    _recentLogs.insert(0, formatted);
    if (_recentLogs.length > 50) _recentLogs.removeLast();
    _syncLogsController.add(formatted);
  }

  /// Wraps an internal store modification with the anti-echo lock.
  void runWithoutSyncEcho(void Function() action) {
    _isApplyingRemoteUpdate = true;
    try {
      action();
    } finally {
      _isApplyingRemoteUpdate = false;
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _transport?.dispose();
    _peerCountController.close();
    _syncLogsController.close();
    _store = null;
  }
}
