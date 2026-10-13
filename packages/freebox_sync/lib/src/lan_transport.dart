import 'dart:typed_data';
import 'lan_transport_interface.dart';
import 'lan_transport_io.dart'
    if (dart.library.js_interop) 'lan_transport_web.dart'
    if (dart.library.html) 'lan_transport_web.dart';

export 'lan_transport_interface.dart';

LanTransport createLanTransport({
  required String nodeId,
  required FrameReceivedCallback onFrameReceived,
  int discoveryPort = 8443,
  int tcpPort = 8444,
}) =>
    LanTransportImpl(
      nodeId: nodeId,
      onFrameReceived: onFrameReceived,
      discoveryPort: discoveryPort,
      tcpPort: tcpPort,
    );
