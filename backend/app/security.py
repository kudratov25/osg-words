"""Admin login: password hashing (scrypt, stdlib only), signed expiring
tokens (HMAC-SHA256), and a small in-memory brute-force throttle."""

import base64
import hashlib
import hmac
import json
import secrets
import time
from collections import defaultdict, deque

from . import config

# --- password hashing -------------------------------------------------------

_SCRYPT_N, _SCRYPT_R, _SCRYPT_P = 2**14, 8, 1


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    digest = hashlib.scrypt(password.encode(), salt=salt, n=_SCRYPT_N, r=_SCRYPT_R, p=_SCRYPT_P)
    return "scrypt${}${}${}${}${}".format(
        _SCRYPT_N, _SCRYPT_R, _SCRYPT_P, _b64(salt), _b64(digest)
    )


def verify_password(password: str, stored: str) -> bool:
    try:
        algo, n, r, p, salt, expected = stored.split("$")
        if algo != "scrypt":
            return False
        digest = hashlib.scrypt(
            password.encode(), salt=_unb64(salt), n=int(n), r=int(r), p=int(p)
        )
        return hmac.compare_digest(digest, _unb64(expected))
    except (ValueError, TypeError):
        return False


# --- tokens -----------------------------------------------------------------

def password_stamp(password_hash: str) -> str:
    """Short fingerprint of the current password hash, put into tokens so a
    password change invalidates every token issued before it."""
    return hashlib.sha256(password_hash.encode()).hexdigest()[:16]


def create_token(username: str, ttl_seconds: int | None = None, stamp: str = "") -> tuple[str, int]:
    """Returns (token, expires_at_unix)."""
    exp = int(time.time()) + (ttl_seconds or config.TOKEN_TTL_HOURS * 3600)
    payload = _b64(json.dumps({"sub": username, "exp": exp, "pv": stamp}, separators=(",", ":")).encode())
    return f"{payload}.{_sign(payload)}", exp


def verify_token(token: str, stamp: str | None = None) -> str | None:
    """Returns the username if the token is authentic and unexpired (and,
    when `stamp` is given, was issued for that password)."""
    try:
        payload, sig = token.split(".")
        if not hmac.compare_digest(sig, _sign(payload)):
            return None
        data = json.loads(_unb64(payload))
        if int(data["exp"]) < time.time():
            return None
        if stamp is not None and not hmac.compare_digest(str(data.get("pv", "")), stamp):
            return None
        return str(data["sub"])
    except (ValueError, KeyError, TypeError):
        return None


def _sign(payload: str) -> str:
    return _b64(hmac.new(config.SECRET_KEY.encode(), payload.encode(), hashlib.sha256).digest())


def _b64(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def _unb64(s: str) -> bytes:
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


# --- brute-force throttle -----------------------------------------------------

MAX_FAILURES = 5
WINDOW_SECONDS = 15 * 60
_failures: dict[str, deque] = defaultdict(deque)


def _prune(ip: str, now: float) -> deque:
    q = _failures[ip]
    while q and q[0] < now - WINDOW_SECONDS:
        q.popleft()
    return q


def is_locked_out(ip: str) -> bool:
    return len(_prune(ip, time.time())) >= MAX_FAILURES


def record_failure(ip: str) -> None:
    _prune(ip, time.time()).append(time.time())


def clear_failures(ip: str) -> None:
    _failures.pop(ip, None)
