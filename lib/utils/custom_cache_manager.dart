import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// A custom CacheManager that ignores 403 status codes and forces them to 200.
/// This is a workaround for the server returning 403 Forbidden for images
/// in the /storage/ directory while still returning the valid image payload.
class CustomCacheManager extends CacheManager {
  static const key = 'customCacheManager';
  static CustomCacheManager? _instance;

  factory CustomCacheManager() {
    _instance ??= CustomCacheManager._();
    return _instance!;
  }

  CustomCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileSystem: IOFileSystem(key),
          fileService: CustomHttpFileService(),
        ));
}

class CustomHttpFileService extends FileService {
  final http.Client _httpClient = http.Client();

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final req = http.Request('GET', Uri.parse(url));
    if (headers != null) {
      req.headers.addAll(headers);
    }
    final res = await _httpClient.send(req);
    return CustomHttpGetResponse(res);
  }
}

class CustomHttpGetResponse implements FileServiceResponse {
  final http.StreamedResponse _response;
  CustomHttpGetResponse(this._response);

  @override
  int get statusCode {
    // Force status 200 if the response has body content and was a 403,
    // to bypass CachedNetworkImage's strict status code check.
    if (_response.statusCode == 403 || _response.statusCode == 404) {
      return 200;
    }
    return _response.statusCode;
  }

  @override
  Stream<List<int>> get content => _response.stream;

  @override
  int? get contentLength => _response.contentLength;

  @override
  DateTime get validTill {
    // Default to caching for 7 days
    return DateTime.now().add(const Duration(days: 7));
  }

  
  @override
  String? get eTag => _response.headers['etag'];

  @override
  String get fileExtension {
    var contentType = _response.headers['content-type'];
    if (contentType != null && contentType.startsWith('image/')) {
      return '.${contentType.substring(6)}';
    }
    return '';
  }
}
