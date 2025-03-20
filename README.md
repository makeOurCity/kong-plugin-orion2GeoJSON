# Kong Plugin: orion2GeoJSON

このKongプラグインは、FIWARE Orion Context Brokerからのレスポンスをインターセプトし、GeoJSON形式に変換するためのものです。

## ファイル構造

```
.
├── kong/
│   └── plugins/
│       └── plugin-orionGeoJSON/
│           ├── handler.lua          # プラグインのメインロジック
│           └── schema.lua           # プラグイン設定のスキーマ定義
├── spec/
│   └── plugin-orionGeoJSON/
│       └── 01-unit_spec.lua        # ユニットテスト
└── plugin-orion2GeoJSON-0.1.0-1.rockspec  # パッケージング設定

~/.kong-pongo/                       # Pongoのグローバル設定ディレクトリ
├── kong-versions/                   # 各バージョンのKongイメージ
├── kong-ee-versions/               # エンタープライズ版Kongイメージ（必要な場合）
└── images/                         # その他の依存イメージ
```

## 開発環境のセットアップ

1. Pongoのインストール:
```bash
curl -Ls https://get.konghq.com/pongo | bash
```

2. 環境変数のセットアップ:
```bash
export PATH=$PATH:~/.local/bin
```

3. プロジェクトの初期化:
```bash
# Pongoの開発環境を初期化
pongo init

# 開発用のプラグインディレクトリに移動
cd ~/.kong-pongo/kong-versions/3.4.1/kong-plugin-orion2GeoJSON

# 開発環境のコンテナを起動
pongo up

# テスト環境のシェルに接続してkmsを実行
pongo shell
# シェル内で以下を実行:
# kms

# この初期化により以下のファイルが生成されます：
# - .pongo/pongo-setup.sh
# - .pongo/pongorc
# - .pongo/postgres-setup.sh
```

注意: Pongoは`~/.kong-pongo`ディレクトリを使用して、必要なDockerイメージやバージョン管理を行います。
このディレクトリには以下が含まれます：
- 各バージョンのKongイメージ
- テスト用のデータベースイメージ
- その他の依存コンテナイメージ
初回実行時に自動的に作成されます。

## 開発とテスト

Pongoを使用してテストを実行:

```bash
# すべてのテストを実行
pongo run

# 特定のテストの実行
pongo run spec/plugin-orionGeoJSON/01-unit_spec.lua

# テスト環境のシェルにアクセス
pongo shell

# テスト環境のクリーンアップ
pongo down
```

## プラグインの設定

Kongの設定ファイル（`kong.conf`）にプラグインを追加:
```bash
plugins = bundled,plugin-orionGeoJSON
```

プラグインの基本的な設定例：

```yaml
plugins:
  - name: plugin-orionGeoJSON
    config:
      example_field: "custom value"
```

## プロダクション環境へのデプロイ

1. プラグインをインストール:
```bash
luarocks make
```

2. Kongを再起動:
```bash
kong restart
```

## ライセンス

Apache License 2.0