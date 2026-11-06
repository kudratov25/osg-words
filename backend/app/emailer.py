"""Sending the login code. Backend chosen by EMAIL_BACKEND (config.py):

  console  writes the email to the log and keeps it in `outbox` (dev/tests)
  smtp     smtplib; STARTTLS on the submission port (587) unless
           SMTP_STARTTLS=0, implicit TLS when SMTP_PORT=465
"""

import logging
import smtplib
import ssl
from collections import deque
from email.message import EmailMessage

from . import config

log = logging.getLogger("osg.email")

# Console backend only: the last messages sent, newest last. Tests read it.
outbox: deque[EmailMessage] = deque(maxlen=100)


class EmailError(Exception):
    pass


def login_code_message(to: str, code: str) -> EmailMessage:
    msg = EmailMessage()
    msg["Subject"] = f"Your OSG code: {code}"
    msg["From"] = config.SMTP_FROM or "OSG <no-reply@localhost>"
    msg["To"] = to
    msg.set_content(
        f"Your OSG code: {code} — valid 10 minutes.\n\n"
        "If you didn't ask for it, you can ignore this email.\n"
    )
    return msg


def send_login_code(to: str, code: str) -> None:
    msg = login_code_message(to, code)
    if config.EMAIL_BACKEND == "console":
        outbox.append(msg)
        log.warning("[console email] to=%s code=%s", to, code)
        return
    if config.EMAIL_BACKEND == "smtp":
        _send_smtp(msg)
        return
    raise EmailError("No email backend configured")


def _send_smtp(msg: EmailMessage) -> None:
    ctx = ssl.create_default_context()
    try:
        if config.SMTP_PORT == 465:
            smtp = smtplib.SMTP_SSL(config.SMTP_HOST, config.SMTP_PORT, timeout=15, context=ctx)
        else:
            smtp = smtplib.SMTP(config.SMTP_HOST, config.SMTP_PORT, timeout=15)
        with smtp:
            smtp.ehlo()
            if config.SMTP_PORT != 465 and config.SMTP_STARTTLS:
                smtp.starttls(context=ctx)
                smtp.ehlo()
            if config.SMTP_USER:
                smtp.login(config.SMTP_USER, config.SMTP_PASSWORD)
            smtp.send_message(msg)
    except (smtplib.SMTPException, OSError) as e:
        log.error("SMTP send failed: %s", e)
        raise EmailError(str(e)) from e
