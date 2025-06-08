import 'dart:async';
import 'dart:io';
import 'package:media_stream/ftp.dart';
import 'package:media_stream/smb.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class MediaStream {
  static final MediaStream _instance = MediaStream._internal(
    host: 'localhost',
    port: 8760,
  );

  factory MediaStream() {
    return _instance;
  }

  HttpServer? _server;
  final String host;
  int port;

  MediaStream._internal({this.host = 'localhost', this.port = 8760});

  Future<void> startServer() async {
    if (_server != null) {
      print('Server is already running at $url');
      return;
    }

    final router = Router();
    router.get('/ftp', _handleFtpStreamRequest);
    router.get('/smb', _handleSmbStreamRequest);
    final handler = const Pipeline().addHandler(router.call);

    while (true) {
      try {
        _server = await io.serve(handler, host, port);
        print('Streaming server started successfully at $url');
        break;
      } on SocketException catch (e) {
        if (e.osError?.errorCode == 10048 ||
            e.osError?.errorCode == 48 ||
            e.osError?.errorCode == 98) {
          print('Port $port is in use, trying port ${port + 1}...');
          port++;
        } else {
          print('An unexpected network error occurred: $e');
        }
      } catch (e) {
        print('An unexpected error occurred during server startup: $e');
      }
    }
  }

  Future stopServer() async {
    await _server?.close();
    _server = null;
    print('Streaming server stopped');
  }

  String? get url {
    if (_server != null) {
      return 'http://${_server!.address.host}:${_server!.port}';
    }
    return null;
  }

  Future<Response> _handleFtpStreamRequest(Request request) async {
    try {
      return await ftpStream(request);
    } catch (e) {
      print('Request processing error: $e');
      return Response.internalServerError(body: 'Error: $e');
    }
  }

  Future<Response> _handleSmbStreamRequest(Request request) async {
    try {
      return await smbStream(request);
    } catch (e) {
      print('Request processing error: $e');
      return Response.internalServerError(body: 'Error: $e');
    }
  }
}
