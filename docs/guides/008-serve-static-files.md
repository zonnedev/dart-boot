# Guide 008: Serve Static Files

## What you'll build

Serve a frontend (HTML, CSS, JS) alongside your Boot API. The API handles `/api/*` routes, and static files serve everything else.

## What you'll learn

- How to configure static file serving
- How caching headers work (ETag, Cache-Control)
- How Boot protects against path traversal attacks
- How to serve a Single Page Application (SPA)
- How to test static file responses

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: Create a public directory

Create a `public/` folder in your project root with some files:

```bash
mkdir -p public/css public/js
```

**`public/index.html`**

```html
<!DOCTYPE html>
<html>
<head>
  <title>Todo App</title>
  <link rel="stylesheet" href="/static/css/style.css">
</head>
<body>
  <h1>Todo App</h1>
  <div id="app"></div>
  <script src="/static/js/app.js"></script>
</body>
</html>
```

**`public/css/style.css`**

```css
body { font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; }
h1 { color: #333; }
```

**`public/js/app.js`**

```javascript
document.getElementById('app').innerHTML = '<p>Loaded!</p>';
fetch('/todos/').then(r => r.json()).then(todos => {
  document.getElementById('app').innerHTML = todos.map(t => `<p>${t.title}</p>`).join('');
});
```

---

## Step 2: Enable static file serving

**`application.yml`** — add under `boot:`:

```yaml
boot:
  static:
    enabled: true
    path: /static
    directory: public/
    index: index.html
    cache:
      max-age: 3600
      etag: true
    gzip: true
```

**What each setting does:**

| Setting | Meaning |
|---|---|
| `enabled: true` | Turn on static file serving |
| `path: /static` | URL prefix — files are served under `/static/*` |
| `directory: public/` | Filesystem folder containing the files |
| `index: index.html` | Default file when a directory is requested |
| `cache.max-age: 3600` | Browser caches files for 1 hour |
| `cache.etag: true` | Generate ETag headers for cache validation |
| `gzip: true` | Serve `.gz` variants if the browser supports it |

---

## Step 3: Build and test

```bash
boot build
boot serve
```

**Access the HTML page:**

```bash
curl http://localhost:8080/static/
```

Returns `public/index.html` (because `index: index.html` is configured).

**Access CSS:**

```bash
curl -v http://localhost:8080/static/css/style.css
```

Response headers:
```
HTTP/1.1 200 OK
content-type: text/css; charset=utf-8
cache-control: public, max-age=3600
etag: "1a2b3c-4d"
last-modified: Sat, 24 May 2026 00:00:00 GMT
```

**Access JS:**

```bash
curl http://localhost:8080/static/js/app.js
```

---

## Step 4: How caching works

### First request

Browser requests `/static/css/style.css`. Boot returns the file with:
- `ETag: "1a2b3c-4d"` — a fingerprint of the file (based on modified time + size)
- `Cache-Control: public, max-age=3600` — browser can cache for 1 hour
- `Last-Modified: Sat, 24 May 2026 ...` — when the file was last changed

### Subsequent requests (within 1 hour)

Browser uses its cached copy. No request to the server at all.

### After cache expires

Browser sends:
```
If-None-Match: "1a2b3c-4d"
```

If the file hasn't changed, Boot returns **304 Not Modified** (no body) — the browser uses its cache. This saves bandwidth.

If the file changed, Boot returns the new file with a new ETag.

---

## Step 5: Security — path traversal protection

A malicious request like:

```bash
curl http://localhost:8080/static/../../etc/passwd
```

Boot normalizes the path and rejects anything that tries to escape the `public/` directory. It returns 404, not the file.

---

## Step 6: Gzip support

If you pre-compress files:

```bash
gzip -k public/js/app.js  # creates app.js.gz alongside app.js
```

When a browser sends `Accept-Encoding: gzip`, Boot serves `app.js.gz` instead of `app.js` — smaller transfer, faster load.

---

## Step 7: Serving a SPA (Single Page Application)

For SPAs (React, Vue, Angular), you want all non-API routes to serve `index.html` so client-side routing works.

The current setup already handles this partially — `/static/` serves `index.html`. But if you want `/app/anything` to also serve the SPA, you'd add a catch-all controller:

```dart
@Controller('/app')
class SpaController {
  @Get('/<path|.*>')
  Future<Response> catchAll(Request request) async {
    // Serve index.html for all /app/* routes
    final file = File('public/index.html');
    return Response.html(await file.readAsString());
  }
}
```

---

## Step 8: Write tests

**`test/static_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('Static files', () {
    test('serves index.html at /static/', () async {
      await bootTest($configure, properties: {
        'boot.static.enabled': 'true',
        'boot.static.path': '/static',
        'boot.static.directory': 'public',
        'boot.static.index': 'index.html',
      }, test: (client, container) async {
        final res = await client.get('/static/');
        res.expectStatus(200);
        expect(res.headers['content-type'], contains('text/html'));
        expect(res.body, contains('<title>Todo App</title>'));
      });
    });

    test('serves CSS with correct content-type', () async {
      await bootTest($configure, properties: {
        'boot.static.enabled': 'true',
        'boot.static.path': '/static',
        'boot.static.directory': 'public',
      }, test: (client, container) async {
        final res = await client.get('/static/css/style.css');
        res.expectStatus(200);
        expect(res.headers['content-type'], contains('text/css'));
        expect(res.body, contains('font-family'));
      });
    });

    test('returns 404 for missing files', () async {
      await bootTest($configure, properties: {
        'boot.static.enabled': 'true',
        'boot.static.path': '/static',
        'boot.static.directory': 'public',
      }, test: (client, container) async {
        final res = await client.get('/static/nonexistent.txt');
        res.expectStatus(404);
      });
    });

    test('path traversal is blocked', () async {
      await bootTest($configure, properties: {
        'boot.static.enabled': 'true',
        'boot.static.path': '/static',
        'boot.static.directory': 'public',
      }, test: (client, container) async {
        final res = await client.get('/static/../../pubspec.yaml');
        res.expectStatus(404);
      });
    });

    test('cache headers are set', () async {
      await bootTest($configure, properties: {
        'boot.static.enabled': 'true',
        'boot.static.path': '/static',
        'boot.static.directory': 'public',
        'boot.static.cache.max-age': '7200',
      }, test: (client, container) async {
        final res = await client.get('/static/css/style.css');
        res.expectStatus(200);
        expect(res.headers['cache-control'], contains('max-age=7200'));
        expect(res.headers['etag'], isNotNull);
      });
    });
  });
}
```

```bash
boot test
```

---

## Step 9: API + Static together

A typical setup: API under `/api/*`, static files under `/static/*`:

```dart
@Controller('/api/todos')
class TodoController { ... }
```

```yaml
boot:
  static:
    enabled: true
    path: /static
    directory: public/
```

- `GET /api/todos/` → controller handles it
- `GET /static/app.js` → static file served
- `GET /static/` → `index.html` served

Boot tries routes first. If no route matches (404), it falls back to static files.

---

## What you've learned

- `boot.static.enabled: true` turns on static serving
- Files are served from a directory with correct MIME types
- ETag + Cache-Control + Last-Modified enable efficient browser caching
- 304 Not Modified saves bandwidth for unchanged files
- Path traversal (`../`) is blocked automatically
- Pre-compressed `.gz` files are served when the browser supports gzip
- Static files are a fallback — API routes always take priority
- `index` config serves a default file for directory requests

## Next steps

- [Guide 009: File Uploads](009-file-uploads.md) — accept file uploads from clients
