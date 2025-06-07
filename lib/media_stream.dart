import 'dart:async';
import 'dart:io';
import 'package:media_stream/ftp.dart';
import 'package:media_stream/smb.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class MediaStream {
  HttpServer? _server;
  final String host;
  final int port;
  MediaStream({this.host = 'localhost', this.port = 8760});

  Future startServer() async {
    if (_server != null) return;
    final router = Router();
    router.get('/ftp', _handleFtpStreamRequest);
    router.get('/smb', _handleSmbStreamRequest);

    final handler = const Pipeline().addHandler(router.call);
    _server = await io.serve(handler, host, port);
    print('Streaming server started at http://$host:$port');
  }

  Future stopServer() async {
    await _server?.close();
    _server = null;
    print('Streaming server stopped');
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
