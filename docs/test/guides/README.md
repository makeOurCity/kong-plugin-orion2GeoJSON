# テスト環境セットアップガイド

## 前提条件

### 必要なソフトウェア
1. DockerとDocker Compose
2. Git
3. Lua開発環境
4. Kong開発ツール

### システム要件
- メモリ: 4GB以上
- ディスク容量: 2GB以上
- CPU: 2コア以上

## インストール手順

### 1. Pongoテストフレームワークのセットアップ

```bash
# Pongoのインストール
curl -Ls https://get.konghq.com/pongo | bash
export PATH=$PATH:~/.local/bin

# インストールの確認
pongo version
```

### 2. プロジェクトの設定

```bash
# クローンとディレクトリ移動
git clone https://github.com/kzkski/kong-plugin-orion2GeoJSON.git
cd kong-plugin-orion2GeoJSON

# Pongoの初期化
pongo init
```

### 3. テスト環境の設定ファイル確認

プラグインには以下の設定ファイルが含まれています：

#### 3.1 .pongo/pongorc
Pongoテストフレームワークの基本設定ファイル。テスト時に必要なサービスを定義します。

```
--orion  # OrionContext Brokerサービスを有効化
--mongo  # MongoDBサービスを有効化
```

#### 3.2 .pongo/orion.yml
Orion Context Brokerのサービス定義ファイル。主な設定：
- イメージ: fiware/orion:3.10.1
- ポート: 1026
- ヘルスチェック設定
- MongoDBとの連携設定

#### 3.3 .pongo/mongo.yml
MongoDBのサービス定義ファイル。主な設定：
- イメージ: mongo:4.4
- ジャーナリング無効化（テスト環境用）
- ヘルスチェック設定

設定ファイルの存在確認：
```bash
# 設定ファイルの確認
ls -l .pongo/

# 各ファイルの内容確認
cat .pongo/pongorc
cat .pongo/orion.yml
cat .pongo/mongo.yml
```

## 環境の検証

### 1. テストフレームワークの確認
```bash
# Pongoのセットアップ確認
pongo info
```

### 2. サービスの確認
```bash
# テスト環境の起動
pongo up

# サービスの実行状態確認
docker ps

# Orionの接続確認
curl localhost:1026/version
```

### 3. テスト実行の確認
```bash
# 簡単なテストの実行
pongo run spec/plugin-orionGeoJSON/01-unit_spec.lua
```

## CI/CD統合

### GitHub Actionsの設定

`.github/workflows/test.yml`の作成：
```yaml
name: テスト実行
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Pongoのセットアップ
        run: |
          curl -Ls https://get.konghq.com/pongo | bash
          export PATH=$PATH:~/.local/bin
      - name: テストの実行
        run: |
          pongo run
```

### テストカバレッジの設定

1. LuaCovのインストール：
```bash
luarocks install luacov
```

2. LuaCovの設定：
```bash
cat > .luacov << EOF
return {
  include = {
    'kong/plugins/orion2GeoJSON/'
  },
  exclude = {
    'spec/'
  }
}
EOF
```

## トラブルシューティング

### よくある問題

1. Pongoの初期化失敗：
```bash
# Dockerサービスの確認
sudo systemctl status docker

# Pongo環境のクリーンアップ
pongo clean
pongo init
```

2. サービスが起動しない：
```bash
# サービスログの確認
docker logs kong-test
docker logs orion-test
docker logs mongo-test

# 環境のリセット
pongo down
pongo up
```

3. ポート競合：
```bash
# ポート使用状況の確認
sudo lsof -i :8000
sudo lsof -i :8001
sudo lsof -i :1026
```

### 環境のクリーンアップ

```bash
# サービスの停止
pongo down

# 完全クリーンアップ
pongo nuke

# テスト成果物の削除
rm -rf tests/output/*
```

## 次のステップ

セットアップ完了後：
1. [テスト実行ガイド](running.md)を参照
2. [テストケース](test_cases/)を確認
3. 必要に応じて[トラブルシューティングガイド](troubleshooting.md)を参照
