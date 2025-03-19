#!/bin/bash

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# スクリプトの場所を取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CLEANUP_SCRIPT="${SCRIPT_DIR}/cleanup.sh"

# 終了時の処理
cleanup() {
    local exit_code=$1
    if [ -x "$CLEANUP_SCRIPT" ]; then
        "$CLEANUP_SCRIPT"
    else
        chmod +x "$CLEANUP_SCRIPT" && "$CLEANUP_SCRIPT"
    fi
    exit $exit_code
}

# SIGINTシグナル（Ctrl+C）のハンドリング
trap 'echo "中断されました" && cleanup 130' INT