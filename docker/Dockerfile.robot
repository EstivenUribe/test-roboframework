FROM python:3.11-slim-bookworm

# ── System deps + Google Chrome ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget gnupg ca-certificates curl \
        libglib2.0-0 libnss3 libnspr4 libdbus-1-3 \
        libatk1.0-0 libatk-bridge2.0-0 libcups2 \
        libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
        libxfixes3 libxrandr2 libgbm1 libasound2 \
    && wget -q -O /usr/share/keyrings/google-chrome.gpg \
        https://dl.google.com/linux/linux_signing_key.pub \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] \
        http://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ── Python deps ───────────────────────────────────────────────────────────────
# opencv-python-headless replaces opencv-python (no Qt/GUI libs required)
RUN pip install --no-cache-dir \
        "robotframework>=6.1.1" \
        "robotframework-seleniumlibrary>=6.2.0" \
        "robotframework-screencaplibrary>=1.5.1" \
        "openpyxl>=3.1.2" \
        "Pillow>=10.0.0" \
        "webdriver-manager>=4.0.1" \
        "opencv-python-headless>=4.9.0" \
        "mss>=9.0.0"

# ── Pre-download ChromeDriver matching installed Chrome ───────────────────────
RUN python -c "\
from webdriver_manager.chrome import ChromeDriverManager; \
path = ChromeDriverManager().install(); \
print('ChromeDriver ready:', path)"

# ── Project source ────────────────────────────────────────────────────────────
COPY robot/ robot/

# ── Output directories ────────────────────────────────────────────────────────
RUN mkdir -p robot/results/logs \
             robot/results/screenshots \
             robot/results/videos \
             robot/data

# ── Entrypoint ────────────────────────────────────────────────────────────────
COPY docker/entrypoint-robot.sh /entrypoint.sh
RUN sed -i 's/\r//' /entrypoint.sh && chmod +x /entrypoint.sh

# ── Runtime defaults (all overrideable with -e) ───────────────────────────────
ENV HEADLESS=true \
    RECORD_VIDEO=false \
    LOGLEVEL=INFO \
    TAGS="" \
    SUITE=""

ENTRYPOINT ["/entrypoint.sh"]
