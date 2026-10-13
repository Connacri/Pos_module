import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'lan_transport_interface.dart';

// In-memory bus for multiple workstations within the same runtime
final _webLanBus = StreamController<Map<String, dynamic>>.broadcast();

class LanTransportImpl implements LanTransport {
  @override
  final String nodeId;
  @override
  final int discoveryPort;
  @override
  final int tcpPort;
  @override
  final FrameReceivedCallback onFrameReceived;

  StreamSubscription? _subscription;
  bool _isDisposed = false;

  LanTransportImpl({
    required this.nodeId,
    required this.onFrameReceived,
    this.discoveryPort = 8443,
    this.tcpPort = 8444,
  });

  @override
  Future<void> start() async {
    _subscription = _webLanBus.stream.listen((message) {
      if (_isDisposed) return;
      final senderNodeId = message['sender'];
      if (senderNodeId == nodeId) return; // Ignore own echoes
      final raw = message['payload'];
      if (raw is List) {
        final bytes = Uint8List.fromList(List<int>.from(raw));
        onFrameReceived(bytes, 'lan_peer_$senderNodeId');
      }
    });
  }

  @override
  void broadcastBinaryFrame(Uint8List frameBytes) {
    if (_isDisposed) return;
    _webLanBus.add({
      'sender': nodeId,
      'payload': frameBytes.toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
  }
}
