// coverage:ignore-file
import 'package:boot_core/boot_core.dart';

import 'http_client.dart';
import 'http_client_config.dart';

part 'http_client_factory.g.dart';

/// Factory that produces the default [HttpClient] bean from [HttpClientConfig].
@Factory()
class HttpClientFactory {
  @Singleton()
  HttpClient httpClient(HttpClientConfig config) => HttpClientBuilder(
        connectTimeout: config.connectTimeout,
        readTimeout: config.readTimeout,
        maxRedirects: config.maxRedirects,
      ).build();
}
