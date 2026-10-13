import 'dart:typed_data';
import 'lan_transport_interface.dart';
import 'lan_transport_io.dart'
    if (dart.library.js_interop) 'lan_transport_web.dart'
    if (dart.library.html) 'lan_transport_web.dart';

export 'lan_transport_interface.dart';

class LanTransport {
  final LanTransport _impl;

  LanTransport({
    required String nodeId,
    required FrameReceivedCallback onFrameReceived,
    int discoveryPort = 8443,
    int tcpPort = 8444,
  }) : _impl = LanTransportImpl(
          nodeId: nodeId,
          onFrameReceived: onFrameReceived,
          discoveryPort: discoveryPort,
          tcpPort: tcpPort,
        );

  String get nodeId => _impl.nodeId;
  int get discoveryPort => _impl.discoveryPort;
  int get tcpPort => _impl.tcpPort;
  FrameReceivedCallback get onFrameReceived => _impl.onFrameReceived;

  Future<void> start() => _impl.start();
  void broadcastBinaryFrame(Uint8List frameBytes) => _impl.broadcastBinaryFrame(frameBytes);
  void dispose() => _impl.dispose();
}
