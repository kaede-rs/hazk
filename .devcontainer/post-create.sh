#!/usr/bin/env bash
# コンテナ作成後に一度だけ実行されるセットアップ処理
set -euo pipefail

echo "==> git の安全なディレクトリ設定"
git config --global --add safe.directory /workspace

echo "==> サブモジュール初期化"
git submodule update --init --recursive

echo "==> キャッシュ用ボリュームの権限を確認"
sudo mkdir -p "$HOME/.cache/ccache" "$HOME/.cache/org.swift.swiftpm"
sudo chown -R "$(id -u):$(id -g)" "$HOME/.cache"

if command -v ccache >/dev/null 2>&1; then
  ccache --max-size=5G >/dev/null
  echo "==> ccache 準備完了 ($(ccache --version | head -n1))"
else
  echo "==> ccache が見つかりません。Dockerfile に追加すると C++ の再ビルドがかなり速くなります"
fi

echo "==> セットアップ完了"