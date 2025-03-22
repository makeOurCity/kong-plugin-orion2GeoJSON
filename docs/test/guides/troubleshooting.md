# トラブルシューティングガイド

## 概要

このガイドでは、orion2GeoJSON Kongプラグインのテスト実行中に発生する可能性のある一般的な問題とその解決方法を説明します。

## よくある問題と解決方法

### 1. 環境セットアップの問題

#### 1.1 Pongoのインストール失敗

**症状：**
- `curl -Ls https://get.konghq.com/pongo | bash`が失敗する
- Pongoコマンドが見つからない

**解決方法：**
```bash
# システム要件の確認
docker --version
docker-compose --version

# 手動インストール
git clone https://github.com/Kong/kong-pongo.git
cd kong-pongo
./pongo.sh up

# PATHへの追加
export PATH=$PATH:$PWD
```

#### 1.2 Dockerサービスが起動しない

**症状：**
- `pongo up`が失敗する
- サービスにアクセスできない

**解決方法：**
```bash
# Dockerの状態確認
sudo systemctl status docker

# ポート競合の確認
sudo lsof -i :8000
sudo lsof -i :8001
sudo lsof -i :1026

# Docker環境のリセット
docker system prune -f
pongo down
pongo up
```

### 2. テスト実行の問題

#### 2.1 ユニットテストの失敗

**症状：**
- spec/plugin-orionGeoJSON/01-unit_spec.luaのテスト失敗

**解決方法：**
1. テスト環境の確認：
```bash
# Luaバージョンの確認
lua -v

# テスト依存関係の確認
pongo info
```

2. 特定のテストのデバッグ：
```bash
# 単一テストを詳細出力付きで実行
pongo run --verbose spec/plugin-orionGeoJSON/01-unit_spec.lua:123
```

#### 2.2 統合テストの失敗

**症状：**
- APIコールの失敗
- タイムアウトエラー

**解決方法：**
1. サービスの確認：
```bash
# サービス状態の確認
curl localhost:1026/version  # Orion
curl localhost:8001/status   # Kong

# ログの確認
docker logs kong-test
docker logs orion-test
```

2. テスト環境のリセット：
```bash
pongo down
pongo up
```

### 3. パフォーマンステストの問題

#### 3.1 レスポンス遅延

**症状：**
- パフォーマンステストがしきい値を超過
- レスポンスの高遅延

**解決方法：**
1. システムリソースの確認：
```bash
# CPU使用率の監視
top

# メモリ確認
free -h

# ディスクI/O確認
iostat -x 1
```

2. テスト環境の最適化：
```bash
# システムキャッシュのクリア
sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches

# サービスの再起動
pongo down
pongo up
```

#### 3.2 メモリ問題

**症状：**
- メモリ不足エラー
- メモリ使用量の増加

**解決方法：**
```bash
# メモリ使用量の監視
watch -n 1 'ps aux | grep kong'

# Kong設定の調整
export KONG_NGINX_WORKER_PROCESSES=auto
export KONG_NGINX_WORKER_CONNECTIONS=2048

# 環境のリセット
pongo down
pongo up
```

### 4. データ整合性の問題

#### 4.1 テストデータの問題

**症状：**
- テスト結果の不整合
- データ未検出エラー

**解決方法：**
```bash
# テストデータのクリーンアップ
curl -X DELETE 'http://localhost:8000/orion/v2/entities?type=Room'

# データ削除の確認
curl 'http://localhost:8000/orion/v2/entities?type=Room'

# テストデータの再作成
./scripts/create_test_data.sh
```

### 5. カバレッジの問題

#### 5.1 低カバレッジレポート

**症状：**
- カバレッジ要件未達
- カバレッジデータ欠落

**解決方法：**
1. カバレッジ設定の確認：
```bash
# .luacov設定の確認
cat .luacov

# 詳細カバレッジ付きで実行
pongo run --coverage --verbose
```

2. 詳細レポートの生成：
```bash
luacov
cat luacov.report.out
```

## デバッグ技法

### 1. デバッグログ

デバッグログの有効化：
```bash
# ログレベルの設定
export KONG_LOG_LEVEL=debug

# テスト実行
pongo run --verbose

# ログの確認
tail -f /usr/local/kong/logs/error.log
```

### 2. リクエストトレース

リクエストトレースの追加：
```lua
-- テストファイルに追加
local function trace_request(request)
  ngx.log(ngx.DEBUG, "リクエスト: ", require("cjson").encode(request))
end
```

### 3. メモリプロファイリング

メモリ使用量の追跡：
```lua
local function profile_memory()
  collectgarbage("collect")
  local before = collectgarbage("count")
  -- テスト実行
  collectgarbage("collect")
  local after = collectgarbage("count")
  ngx.log(ngx.INFO, "メモリ変化: ", after - before, "KB")
end
```

## 予防策

### 1. テスト前チェックリスト

✅ 環境がクリーンで準備完了
✅ 全サービスが起動中
✅ テストデータが準備済み
✅ システムリソースが十分
✅ ログがクリア

### 2. 監視設定

```bash
# 監視スクリプトの作成
cat > monitor.sh << EOF
#!/bin/bash
while true; do
  echo "=== システム状態 ==="
  free -h
  ps aux | grep kong
  sleep 5
done
EOF
chmod +x monitor.sh
```

## サポート取得

### 1. ログ収集

サポート用ログの収集：
```bash
# ログバンドルの作成
./scripts/collect_logs.sh

# システム情報の含める
uname -a > system_info.txt
docker info >> system_info.txt
```

### 2. サポートリソース

- [Kongフォーラム](https://discuss.konghq.com/)
- [Kong GitHub Issues](https://github.com/Kong/kong/issues)
- [Pongoドキュメント](https://github.com/Kong/kong-pongo)

### 3. 問題報告時の注意点

問題報告時には以下を含めてください：
1. 環境詳細
2. 再現手順
3. 期待される結果と実際の結果
4. 関連ログ
5. テスト設定