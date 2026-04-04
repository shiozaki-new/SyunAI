# CHANGELOG_AI - 変更ファイル一覧

## 新規作成ファイル (25ファイル)

### 設定
- `project.yml` - XcodeGenプロジェクト定義
- `.gitignore` - Git除外設定

### Shared
- `Shared/Constants.swift` - アプリ定数、APIエンドポイント、クイックプロンプト
- `Shared/Models/ChatMessage.swift` - チャットメッセージモデル
- `Shared/Models/GemmaModels.swift` - Google AI API リクエスト/レスポンス構造体

### WatchApp
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

### iPhoneApp
- `iPhoneApp/App/SyunAIApp.swift` - @main エントリポイント
- `iPhoneApp/Views/PhoneHomeView.swift` - メイン画面 + オンボーディング
- `iPhoneApp/Services/PhoneConnectivityService.swift` - WCSession管理
- `iPhoneApp/Services/PhoneKeychainService.swift` - Keychain CRUD
- `iPhoneApp/Info.plist` - iOS設定 (暗号化申告、権限文言)
- `iPhoneApp/SyunAI.entitlements` - エンタイトルメント

### Asset Catalogs
- `iPhoneApp/Assets.xcassets/AppIcon.appiconset/AppIcon.png` - 1024x1024アイコン
- `iPhoneApp/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `iPhoneApp/Assets.xcassets/AccentColor.colorset/Contents.json` - シアンカラー
- `iPhoneApp/Assets.xcassets/Contents.json`
- `WatchApp/Assets.xcassets/` (同構造)

### ドキュメント
- `WORKLOG.md` - 作業ログ
- `RELEASE_STATUS.md` - リリース状態
- `NEXT_ACTIONS.md` - 次のアクション
- `CHANGELOG_AI.md` - 本ファイル

## 重要な設計判断

### ChatGPTWatchからの変更点
| 項目 | ChatGPTWatch | SyunAI |
|------|-------------|--------|
| API | OpenAI (GPT-4o) | Google AI Studio (Gemma) |
| 認証 | Bearer token | URL query parameter |
| 料金 | 有料 | 無料枠あり |
| 言語 | 英語中心 | 日本語ファースト |
| Watch UI | 汎用チャット | クイックプロンプト特化 |
| iPhone UI | 詳細設定多数 | 簡素 (設定+同期のみ) |
| トークン制限 | 300 (Watch) | 200 (Watch) - より短い応答 |
| システムプロンプト | 100語以内の英語 | 50文字以内の日本語 |

### アーキテクチャ
- Watch: 直接APIコール (iPhone不要で動作可能)
- iPhone: APIキー管理 + WatchConnectivityで設定同期
- Keychain: デバイス間でAPIキー安全共有
