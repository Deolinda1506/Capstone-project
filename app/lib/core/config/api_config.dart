/// Backend API base URL (no trailing slash).
///
/// **Default:** `http://localhost:8000` — only works when the FastAPI server is
/// running on the **same machine** as the app (e.g. `uvicorn` on port 8000).
///
/// If the browser shows `ERR_CONNECTION_REFUSED` for `/auth/register` or similar:
/// - **Flutter web / Chrome:** either start the API locally, or point at a deployed API.
/// - **Android emulator:** `localhost` is the emulator itself — use `http://10.0.2.2:8000`
///   for the host machine’s API.
/// - **Physical phone:** use your computer’s LAN IP, e.g. `http://192.168.1.x:8000`,
///   or use the deployed API URL.
///
/// **Examples** (from repo root, `app/`):
/// ```bash
/// flutter run -d chrome --dart-define=API_BASE_URL=https://carotidcheck-api.onrender.com
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
/// ```
class ApiConfig {
  ApiConfig._();

  static String get baseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000',
      );
}
