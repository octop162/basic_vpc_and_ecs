FROM mcr.microsoft.com/devcontainers/base:debian

# Install ecspresso
RUN curl -fsSL https://github.com/kayac/ecspresso/releases/download/v2.5.0-nightly-f361aa7/ecspresso_2.5.0-nightly-f361aa7_linux_amd64.tar.gz \
    | tar -xzC /usr/local/bin ecspresso \
    && chmod +x /usr/local/bin/ecspresso