# CHANGELOG_AI - 変更ファイル一覧

## v2.0.0 無料運用版 (2026-04-05)

### 削除ファイル (3)
- `iPhoneApp/Services/PhoneKeychainService.swift` - API キー Keychain 管理（不要に）
- `WatchApp/Services/KeychainService.swift` - Watch 側 Keychain 管理（不要に）
- `Shared/Models/GemmaModels.swift` - Gemini API リクエスト/レスポンスモデル（不要に）

### 新規作成ファイル (4)
- `iPhoneApp/Services/LocalLLMService.swift` - llama.cpp C API ラッパー、モデル読み込み・推論
- `iPhoneApp/Services/ModelManager.swift` - モデルダウンロード・ライフサイクル管理
- `Shared/LocalUtility.swift` - 日時・計算・単位変換のローカル処理
- `Frameworks/llama.xcframework` - llama.cpp b8664 XCFramework (iOS/macOS/watchOS/tvOS)

### 大幅書き換えファイル (10)
- `project.yml` - SPM 依存削除、XCFramework 参照、バージョン 2.0.0
- `Shared/Constants.swift` - API 設定廃止、ローカルモデル設定・推論設定追加
- `Shared/Models/ChatMessage.swift` - apiMessage プロパティ削除
- `iPhoneApp/App/SyunAIApp.swift` - ModelManager を StateObject として追加
- `iPhoneApp/Views/PhoneHomeView.swift` - API キー UI → モデルダウンロード UI + v2 オンボーディング
- `iPhoneApp/Services/PhoneConnectivityService.swift` - 設定同期 → 推論リクエスト中継
- `WatchApp/ViewModels/WatchChatViewModel.swift` - 直接 API コール → WC 経由推論リクエスト
- `WatchApp/Services/WatchConnectivityService.swift` - 設定受信 → 推論リクエスト送受信
- `WatchApp/Views/WatchHomeView.swift` - API キー未設定表示 → iPhone 接続/モデル状態表示
- `WatchApp/Views/WatchSettingsView.swift` - API キーステータス → モデル/接続ステータス、v2.0.0

### ドキュメント更新 (4)
- `WORKLOG.md` - v2.0.0 作業ログ追記
- `RELEASE_STATUS.md` - v2.0.0 ステータス追加
- `NEXT_ACTIONS.md` - v2.0.0 向けアクションに更新
- `CHANGELOG_AI.md` - 本ファイル

### 変更なしファイル
- `WatchApp/App/SyunAIWatchApp.swift` - 変更不要
- `WatchApp/Views/WatchInputView.swift` - 変更不要
- `WatchApp/Views/WatchMessageBubble.swift` - 変更不要
- `WatchApp/Info.plist` - 変更不要
- `WatchApp/SyunAI.entitlements` - 変更不要
- `iPhoneApp/Info.plist` - 変更不要
- `iPhoneApp/SyunAI.entitlements` - 変更不要
- `iPhoneApp/Assets.xcassets/` - 変更不要
- `WatchApp/Assets.xcassets/` - 変更不要
- `.gitignore` - 変更不要

---

## 重要な設計判断 (v2)

### v1 → v2 変更対照表
| 項目 | v1 (API版) | v2 (ローカル版) |
|------|-----------|----------------|
| 推論 | Google AI Studio (クラウド) | llama.cpp (iPhone ローカル) |
| 認証 | API キー (URL パラメータ) | 不要 |
| 料金 | 無料枠あり (制限付き) | 完全無料 |
| モデル | Gemma 3 4B/12B/27B (サーバー側) | Gemma 2 2B (GGUF, デバイス上) |
| Watch 動作 | Watch が直接 API コール | Watch → iPhone (WC) → ローカル推論 |
| セットアップ | API キー入力 + Watch 同期 | モデルダウンロード (初回のみ) |
| ネットワーク | 推論ごとに必要 | 初回ダウンロード後は不要 |
| 配布 | API キー配布が課題 | アプリだけで完結 |

### アーキテクチャ (v2)
```
[Apple Watch] -- WatchConnectivity --> [iPhone]
     UI のみ                            LocalLLMService (llama.cpp)
     質問送信                           ModelManager (ダウンロード)
     回答表示                           LocalUtility (日時/計算)
                                        PhoneConnectivityService (中継)
```

### ローカルユーティリティで LLM をバイパスするケース
- 現在時刻・今日の日付・曜日
- 四則演算 (NSExpression)
- 単位変換 (km↔マイル, kg↔ポンド, °C↔°F, cm↔インチ)

---

## v1.0.0 (初期版, 2026-04-04)

### 新規作成ファイル (25ファイル)

#### 設定
- `project.yml` - XcodeGenプロジェクト定義
- `.gitignore` - Git除外設定

#### Shared
- `Shared/Constants.swift` - アプリ定数、APIエンドポイント、クイックプロンプト
- `Shared/Models/ChatMessage.swift` - チャットメッセージモデル
- `Shared/Models/GemmaModels.swift` - Google AI API リクエスト/レスポンス構造体

#### WatchApp
- `WatchApp/App/SyunAIWatchApp.swift` - @main エントリポイント
- `WatchApp/ViewModels/WatchChatViewModel.swift` - API呼び出し、メッセージ管理、永続化
- `WatchApp/Views/WatchHomeView.swift` - メイン画面 (3状態: APIキーなし/空/チャット)
- `WatchApp/Views/WatchInputView.swift` - 質問入力 + 5つのクイックプロンプト
- `WatchApp/Views/WatchMessageBubble.swift` - メッセージバブルUI
- `WatchApp/Views/WatchSettingsView.swift` - 設定画面
- `WatchApp/Services/KeychainService.swift` - Keychain CRUD
- `WatchApp/Services/WatchConnectivityService.swift` - WCSession管理
- `WatchApp/Info.plist` - watchOS設定 (WKApplication, 暗号化申告)
- `WatchApp/SyunAI.entitlements` - エンタイトルメント

#### iPhoneApp
- `iPhoneApp/App/SyunAIApp.swift` - @main エントリポイント
- `iPhoneApp/Views/PhoneHomeView.swift` - メイン画面 + オンボーディング
- `iPhoneApp/Services/PhoneConnectivityService.swift` - WCSession管理
- `iPhoneApp/Services/PhoneKeychainService.swift` - Keychain CRUD
- `iPhoneApp/Info.plist` - iOS設定 (暗号化申告、権限文言)
- `iPhoneApp/SyunAI.entitlements` - エンタイトルメント

#### Asset Catalogs
- `iPhoneApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png` - 1024x1024アイコン
- `iPhoneApp/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `iPhoneApp/Assets.xcassets/AccentColor.colorset/Contents.json` - シアンカラー
- `iPhoneApp/Assets.xcassets/Contents.json`
- `WatchApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png` - Watch用アイコン
- `WatchApp/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `WatchApp/Assets.xcassets/AccentColor.colorset/Contents.json`
- `WatchApp/Assets.xcassets/Contents.json`

#### ドキュメント
- `WORKLOG.md` - 作業ログ
- `RELEASE_STATUS.md` - リリース状態
- `NEXT_ACTIONS.md` - 次のアクション
- `CHANGELOG_AI.md` - 本ファイル
