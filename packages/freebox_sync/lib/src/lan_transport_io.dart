import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'lan_transport_interface.dart';

class LanTransportImpl implements LanTransport {
  @override
  final String nodeId;
  @override
  final int discoveryPort;
  @override
  final int tcpPort;
  @override
  final FrameReceivedCallback onFrameReceived;

  RawDatagramSocket? _udpSocket;
  ServerSocket? _tcpServer;
  final Map<String, Socket> _connectedPeers = {};
  Timer? _beaconTimer;
  bool _isDisposed = false;

  LanTransportImpl({
    required this.nodeId,
    required this.onFrameReceived,
    this.discoveryPort = 8443,
    this.tcpPort = 8444,
  });

  @override
  Future<void> start() async {
    try {
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort);
      _tcpServer!.listen(_handleIncomingClient);
    } catch (_) {}

    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
      _udpSocket!.broadcastEnabled = true;
      _udpSocket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final dg = _udpSocket!.receive();
          if (dg != null) {
            _handleUdpPacket(dg);
          }
        }
      });

      _beaconTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_isDisposed) return;
        _broadcastUdpBeacon();
      });
    } catch (_) {}
  }

  void _broadcastUdpBeacon() {
    try {
      final message = 'FREEBOX_PEER:$nodeId:$tcpPort';
      final data = Uint8List.fromList(message.codeUnits);
      _udpSocket?.send(data, InternetAddress('255.255.255.255'), discoveryPort);
    } catch (_) {}
  }

  void _handleUdpPacket(Datagram dg) {
    try {
      final msg = String.fromCharCodes(dg.data);
      if (msg.startsWith('FREEBOX_PEER:')) {
        final parts = msg.split(':');
        final peerNodeId = parts[1];
        final port = int.tryParse(parts[2]) ?? tcpPort;

        if (peerNodeId != nodeId) {
          final peerIp = dg.address.address;
          _connectToPeer(peerIp, port);
        }
      }
    } catch (_) {}
  }

  Future<void> _connectToPeer(String ip, int port) async {
    if (_connectedPeers.containsKey(ip)) return;
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 1500));
      _connectedPeers[ip] = socket;
      _listenToSocket(socket, ip);
    } catch (_) {}
  }

  void _handleIncomingClient(Socket client) {
    final ip = client.remoteAddress.address;
    _connectedPeers[ip] = client;
    _listenToSocket(client, ip);
  }

  void _listenToSocket(Socket socket, String ip) {
    socket.listen(
      (data) {
        onFrameReceived(Uint8List.fromList(data), ip);
      },
      onError: (_) {
        _connectedPeers.remove(ip);
      },
      onDone: () {
        _connectedPeers.remove(ip);
      },
      cancelOnError: true,
    );
  }

  @override
  void broadcastBinaryFrame(Uint8List frameBytes) {
    for (final peer in _connectedPeers.values) {
      try {
        peer.add(frameBytes);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _beaconTimer?.cancel();
    _udpSocket?.close();
    _tcpServer?.close();
    for (final socket in _connectedPeers.values) {
      socket.close();
    }
    _connectedPeers.clear();
  }
}
