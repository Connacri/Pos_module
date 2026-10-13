import 'dart:typed_data';

typedef FrameReceivedCallback = void Function(Uint8List bytes, String peerAddress);

abstract class LanTransport {
  String get nodeId;
  int get discoveryPort;
  int get tcpPort;
  FrameReceivedCallback get onFrameReceived;

  Future<void> start();
  void broadcastBinaryFrame(Uint8List frameBytes);
  void dispose();
}
