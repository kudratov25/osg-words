"""Admin login settings.

    python -m app.set_password            # prompts, prints .env lines
    python -m app.set_password --reset    # forgot the panel password: delete the
                                          # one set in the panel, so .env applies again

A password changed in the admin panel (Settings → Change password) is stored
in the database and takes precedence over ADMIN_PASSWORD_HASH in .env.
"""

import getpass
import secrets
import sys

from .security import hash_password


def reset() -> None:
    from sqlmodel import Session

    from .database import engine, init_db
    from .models import AdminCredential

    init_db()
    with Session(engine) as session:
        row = session.get(AdminCredential, 1)
        if not row:
            print("No panel-set password in the database; .env is already in use.")
            return
        session.delete(row)
        session.commit()
    print("Panel-set password removed. Log in with ADMIN_USERNAME / ADMIN_PASSWORD_HASH from .env")
    print("(run without --reset to generate a new hash, then restart the service).")


def main() -> None:
    if "--reset" in sys.argv[1:]:
        reset()
        return
    username = input("Admin username [admin]: ").strip() or "admin"
    pw = getpass.getpass("New admin password (min 10 chars): ")
    if len(pw) < 10:
        raise SystemExit("Password too short.")
    if pw != getpass.getpass("Repeat password: "):
        raise SystemExit("Passwords don't match.")
    print("\nPut these lines in .env (replace existing ones):\n")
    print(f"ADMIN_USERNAME={username}")
    print(f"ADMIN_PASSWORD_HASH={hash_password(pw)}")
    print(f"SECRET_KEY={secrets.token_urlsafe(32)}")


if __name__ == "__main__":
    main()
