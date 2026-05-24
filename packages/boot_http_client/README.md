# boot_http_client

HTTP client module for the Boot Framework.

## Features

- `HttpClient` — configured client with timeouts, headers, filters
- `HttpClientBuilder` — fluent builder API
- `@Client` — compile-time generated client from interface
- `@ClientFilter` — outgoing request filters
- `ClientResponse` — response with json/jsonList helpers
- Auto error throwing for 4xx/5xx responses
