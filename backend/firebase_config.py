"""Firebase Admin SDK configuration for authentication only."""
import os
from pathlib import Path
import firebase_admin
from firebase_admin import credentials, auth

# Backend dir (key lives next to backend code)
_BACKEND_ROOT = Path(__file__).resolve().parent
_raw_path = os.getenv("FIREBASE_KEY_PATH", "firebase-key.json")
firebase_key_path = Path(_raw_path) if Path(_raw_path).is_absolute() else (_BACKEND_ROOT / _raw_path)

if firebase_key_path.exists():
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(firebase_key_path))
        firebase_admin.initialize_app(cred)
    print("✅ Firebase initialized: Authentication only")
else:
    print(f"⚠️  Firebase not initialized. Create {firebase_key_path} from Firebase Console.")


def verify_firebase_token(id_token: str) -> str:
    """Verify Firebase ID token and return the Firebase UID."""
    decoded = _decode_firebase_token(id_token)
    return decoded['uid']


def _decode_firebase_token(id_token: str) -> dict:
    """Verify Firebase ID token and return the full decoded payload (uid, email, name, etc.)."""
    try:
        return auth.verify_id_token(id_token)
    except Exception as e:
        raise ValueError(f"Invalid Firebase token: {str(e)}")
