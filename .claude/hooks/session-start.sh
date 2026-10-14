#!/bin/bash
# Prepares Claude Code cloud sessions: pinned Node/npm, submodules, dependencies, build.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

NODE_VERSION="$(tr -d '[:space:]v' < .nvmrc)"
NPM_VERSION="$(node -p "require('./package.json').packageManager.split('@')[1]")"

if [ "$(/usr/local/bin/node -v 2>/dev/null || true)" != "v${NODE_VERSION}" ]; then
  tmp="$(mktemp -d)"
  archive="node-v${NODE_VERSION}-linux-x64.tar.xz"
  curl -fsSL -o "$tmp/$archive" "https://nodejs.org/dist/v${NODE_VERSION}/${archive}"
  (cd "$tmp" && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" | grep " ${archive}\$" | sha256sum -c -)
  tar -xJf "$tmp/$archive" -C /usr/local --strip-components=1
  rm -rf "$tmp"
fi

export PATH="/usr/local/bin:$PATH"
echo 'export PATH="/usr/local/bin:$PATH"' >> "$CLAUDE_ENV_FILE"

if [ "$(npm -v)" != "$NPM_VERSION" ]; then
  npm install -g "npm@${NPM_VERSION}" --no-fund --no-audit
fi

git submodule update --init --recursive

npm install --no-fund --no-audit
npm run build:cached
