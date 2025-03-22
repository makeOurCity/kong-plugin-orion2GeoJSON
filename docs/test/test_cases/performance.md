# パフォーマンステストケース仕様

## 概要

パフォーマンステストでは、様々な負荷条件下でのプラグインの動作を評価します。レスポンスタイム、メモリ使用量、システム安定性を測定します。

## テスト環境要件

### ハードウェア要件
- CPU: 4コア以上
- メモリ: 8GB以上
- ディスク: SSD（20GB以上の空き容量）

### ソフトウェア設定
- Kongレート制限: 無効
- データベース: 専用インスタンス
- ネットワーク: 分離されたテストネットワーク

## テストカテゴリー

### 1. レスポンスタイムテスト

#### 1.1 単一エンティティのレスポンスタイム
```lua
-- テスト設定
local config = {
  num_requests = 1000,
  concurrent = 1,
  entity_size = "small" -- 約1KB
}

-- 期待される結果
local expectations = {
  avg_response_time = "50ms未満",
  p95_response_time = "100ms未満",
  p99_response_time = "200ms未満"
}

-- テスト実装
describe("単一エンティティのレスポンスタイム", function()
  it("レスポンスタイム要件を満たすこと", function()
    local times = {}
    for i = 1, config.num_requests do
      local start_time = ngx.now()
      -- リクエスト実行
      local response = client:get("/orion/v2/entities/Room1")
      local end_time = ngx.now()
      times[i] = end_time - start_time
    end
    assert.is_true(calculate_percentile(times, 95) < 0.1)
  end)
end)
```

#### 1.2 バッチエンティティのレスポンスタイム
```lua
-- テスト設定
local batch_config = {
  num_requests = 100,
  concurrent = 1,
  entities_per_request = 100
}

-- 期待される結果
local batch_expectations = {
  avg_response_time = "500ms未満",
  p95_response_time = "1s未満",
  max_response_time = "2s未満"
}
```

### 2. 同時リクエストテスト

#### 2.1 負荷テスト設定
| パラメータ | 値 | 説明 |
|-----------|-----|------|
| 同時ユーザー数 | 50 | 同時接続数 |
| ランプアップ期間 | 30秒 | 最大負荷までの時間 |
| テスト時間 | 5分 | 総テスト時間 |
| リクエストレート | 100/秒 | 1秒あたりのリクエスト数 |

#### 2.2 テストシナリオ
```lua
-- 基本的な負荷テスト
local function run_load_test()
  local threads = {}
  for i = 1, 50 do
    threads[i] = ngx.thread.spawn(function()
      for j = 1, 100 do
        -- リクエスト実行
        local response = client:get("/orion/v2/entities?type=Room")
        -- レスポンス検証
        assert.response(response).has.status(200)
      end
    end)
  end
  -- 全スレッドの完了待ち
  for _, thread in ipairs(threads) do
    ngx.thread.wait(thread)
  end
end
```

### 3. メモリ使用量テスト

#### 3.1 メモリ消費の監視
```lua
-- メモリ追跡
local function track_memory_usage()
  local initial_mem = collectgarbage("count")
  
  -- テスト負荷の生成
  local large_entities = generate_test_entities(1000)
  local result = convert_entity_array(large_entities, config)
  
  local final_mem = collectgarbage("count")
  return final_mem - initial_mem
end

-- テストケース
it("メモリ使用量が安定していること", function()
  local memory_increase = track_memory_usage()
  assert.is_true(memory_increase < 1024) -- 1MB未満の増加
end)
```

#### 3.2 メモリしきい値
| 操作 | 最大メモリ増加 |
|------|--------------|
| 単一エンティティ | 50KB |
| 100エンティティ | 500KB |
| 1000エンティティ | 3MB |

### 4. 持続負荷テスト

#### 4.1 長時間テスト設定
```lua
-- テスト設定
local endurance_config = {
  duration = 3600, -- 1時間
  request_rate = 10, -- 1秒あたりのリクエスト数
  check_interval = 60 -- 確認間隔（秒）
}

-- 監視メトリクス
local metrics = {
  response_times = {},
  error_counts = {},
  memory_usage = {}
}

-- テスト実装
local function run_endurance_test()
  local start_time = ngx.now()
  while ngx.now() - start_time < endurance_config.duration do
    -- リクエスト実行
    -- メトリクス収集
    -- しきい値確認
    ngx.sleep(1/endurance_config.request_rate)
  end
end
```

#### 4.2 安定性基準
| メトリクス | しきい値 |
|-----------|---------|
| エラー率 | 0.1%未満 |
| メモリ増加 | 10MB/時未満 |
| レスポンスタイム劣化 | 10%未満 |

## テストデータ生成

### 1. エンティティ生成器
```lua
local function generate_test_entities(count, size)
  local entities = {}
  for i = 1, count do
    entities[i] = {
      id = string.format("Room%d", i),
      type = "Room",
      location = {
        value = {
          type = "Point",
          coordinates = {13.3986112, 52.554699}
        },
        type = "geo:json"
      }
    }
    -- サイズに応じて追加プロパティを設定
    if size == "large" then
      -- プロパティ追加
    end
  end
  return entities
end
```

### 2. テストデータサイズ
| サイズ | プロパティ数 | 合計サイズ |
|--------|-------------|------------|
| 小 | 5 | 約1KB |
| 中 | 20 | 約5KB |
| 大 | 100 | 約20KB |

## パフォーマンステストの実行

### 1. 準備
```bash
# テスト環境のクリーンアップ
pongo down
pongo up

# システムのウォームアップ
./scripts/warmup.sh
```

### 2. テスト実行
```bash
# パフォーマンステストの実行
pongo run spec/plugin-orionGeoJSON/03-performance_spec.lua

# 詳細メトリクス付きで実行
pongo run --perf-output=perf.json spec/plugin-orionGeoJSON/03-performance_spec.lua
```

### 3. 結果分析
```bash
# パフォーマンスレポート生成
./scripts/analyze_performance.sh perf.json

# メモリ使用量確認
./scripts/check_memory_usage.sh
```

## パフォーマンス監視

### 1. メトリクス収集
- レスポンスタイム
- メモリ使用量
- エラー率
- CPU使用率

### 2. ログ記録
```lua
-- パフォーマンスメトリクスのログ記録
local function log_performance_metrics(metrics)
  ngx.log(ngx.INFO, "パフォーマンスメトリクス: ", cjson.encode(metrics))
end
```

### 3. アラートしきい値
| メトリクス | 警告 | 重大 |
|-----------|------|------|
| レスポンスタイム | 500ms超 | 1s超 |
| メモリ使用量 | 80%超 | 90%超 |
| エラー率 | 1%超 | 5%超 |

## 結果レポート

### 1. レポート形式
```json
{
  "summary": {
    "total_requests": 1000,
    "success_rate": 99.9,
    "avg_response_time": 45.2,
    "p95_response_time": 95.1,
    "max_memory_usage": 2048
  },
  "details": {
    "response_times": [...],
    "memory_usage": [...],
    "error_logs": [...]
  }
}
```

### 2. 可視化
- レスポンスタイム分布グラフ
- メモリ使用量の時系列グラフ
- エラー率の推移
- 負荷とレスポンスタイムの相関グラフ