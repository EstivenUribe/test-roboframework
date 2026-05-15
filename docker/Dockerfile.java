# ═══════════════════════════════════════════════════════════════════════════════
# Stage 1 — Generate Excel with Python (lightweight throwaway stage)
# ═══════════════════════════════════════════════════════════════════════════════
FROM python:3.11-slim-bookworm AS excel-generator

RUN pip install --no-cache-dir "openpyxl>=3.1.2"

WORKDIR /gen
COPY robot/data/generar_datos.py .
RUN python generar_datos.py


# ═══════════════════════════════════════════════════════════════════════════════
# Stage 2 — Maven + JDK 11 + Chrome test runner
# ═══════════════════════════════════════════════════════════════════════════════
FROM eclipse-temurin:11-jdk-jammy AS test-runner

# ── System deps + Google Chrome ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        wget gnupg ca-certificates \
    && wget -q -O /usr/share/keyrings/google-chrome.gpg \
        https://dl.google.com/linux/linux_signing_key.pub \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] \
        http://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ── Install Maven 3.9.6 ───────────────────────────────────────────────────────
RUN wget -q \
        https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz \
    && tar -xzf apache-maven-3.9.6-bin.tar.gz -C /opt \
    && ln -s /opt/apache-maven-3.9.6 /opt/maven \
    && rm apache-maven-3.9.6-bin.tar.gz

ENV PATH="/opt/maven/bin:${PATH}" \
    MAVEN_OPTS="-Xmx512m"

WORKDIR /app/java

# ── Pre-download Maven dependencies (cache layer) ─────────────────────────────
# Copy pom.xml alone so this layer is only invalidated when dependencies change
COPY java/pom.xml .
RUN mvn dependency:go-offline --no-transfer-progress -q

# ── Copy Java source + TestNG suites ─────────────────────────────────────────
COPY java/src         src/
COPY java/testng.xml  testng.xml
COPY java/testng-headless.xml testng-headless.xml

# ── Copy Excel generated in Stage 1 ──────────────────────────────────────────
COPY --from=excel-generator /gen/datos_prueba.xlsx src/test/resources/datos_prueba.xlsx

# ── Output directories ────────────────────────────────────────────────────────
RUN mkdir -p target/screenshots \
             target/videos \
             target/extent-reports

# ── Entrypoint ────────────────────────────────────────────────────────────────
COPY docker/entrypoint-java.sh /entrypoint.sh
RUN sed -i 's/\r//' /entrypoint.sh && chmod +x /entrypoint.sh

# ── Runtime defaults (all overrideable with -e) ───────────────────────────────
ENV TESTNG_FILE=testng.xml \
    TEST_CLASS=""

ENTRYPOINT ["/entrypoint.sh"]
