# boot_http_common

Shared HTTP primitives for the Boot Framework.

## Features

- `Request` — immutable HTTP request with JSON/multipart parsing
- `Response` — HTTP response with factory constructors (json, created, noContent, etc.)
- `FilterChain` / `ClientFilterChain` — server and client filter chains
- `HttpServerFilter` / `HttpClientFilter` — filter interfaces
- `@ServerFilter` / `@ClientFilter` — filter annotations
- HTTP exceptions (BadRequest, NotFound, Unauthorized, etc.)
- `FormData` / `MultipartFile` — multipart parsing
