# SyunAI WORKLOG

## 実施日: 2026-04-04

### Phase 1: プロジェクト構築
- ChatGPTWatchの構造を分析し、SyunAI用に再設計
- Google AI Studio API (Gemma モデル) ベースのアーキテクチャを採用
- XcodeGen (project.yml) でiPhone + watchOS デュアルターゲット構成
- Bundle ID: `com.syunai.app` (iPhone), `com.syunai.app.watchkitapp` (Watch)
- Team ID: M878XBQ25U

### Phase 2: ソースコード作成
**Shared (3ファイル)**
- `Constants.swift` - API設定、クイックプロンプト、UserDefaultsキー
- `Models/ChatMessage.swift` - メッセージモデル
- `Models/GemmaModels.swift` - Google AI API リクエスト/レスポンスモデル

**WatchApp (8ファイル)**
- `App/SyunAIWatchApp.swift` - エントリポイント
- `ViewModels/WatchChatViewModel.swift` - チャットロジック、API呼び出し
- `Views/WatchHomeView.swift` - メインUI (空状態/チャット/APIキー未設定)
- `Views/WatchInputView.swift` - 質問入力 + クイックプロンプト
- `Views/WatchMessageBubble.swift` - メッセージ表示
- `Views/WatchSettingsView.swift` - 設定画面
- `Services/KeychainService.swift` - APIキー安全保管
- `Services/WatchConnectivityService.swift` - iPhone連携

**iPhoneApp (4ファイル)**
- `App/SyunAIApp.swift` - エントリポイント
- `Views/PhoneHomeView.swift` - メインUI + オンボーディング
- `Services/PhoneConnectivityService.swift` - Watch連携
- `Services/PhoneKeychainService.swift` - APIキー保管

### Phase 3: ビルド・修正
- UUID/String型不一致エラー修正 (WatchHomeView.swift line 104)
- CoreSimulator/actool問題 (AssetCatalogSimulatorAgent起動失敗)
  - Watch/iPhone双方のAsset Catalogをビルドから除外して回避
  - この問題はMac再起動で解消される既知のシステムバグ
- repo の最終状態としては Asset Catalog を再度有効化し、`WatchApp/Assets.xcassets` も追加済み
- 再起動なしでは iPhone / Watch とも `actool --output-partial-info-plist` が同じエラーで再現することを確認

### Phase 4: Archive
- `xcodebuild archive` 成功 (Assets除外状態)
- Archive場所: `~/Library/Developer/Xcode/Archives/2026-04-04/SyunAI iPhone 2026-04-04, 21.58.xcarchive`
- Watch Appも含まれていることを確認

### Phase 5: App Store Connect設定
- Developer Portal: Bundle ID登録完了
  - `com.syunai.app` (iPhone)
  - `com.syunai.app.watchkitapp` (Watch)
- App Store Connect: アプリ「SyunAI」作成完了 (App ID: 6761652986)
- TestFlight: 内部テストグループ「syunai-internal」作成完了
- テスター: skstudio8004430@gmail.com 追加完了

### Phase 6: アップロード (未完了)
- Distribution証明書が未作成のため `xcodebuild -exportArchive` 失敗
- Xcodeの Accounts 設定が空であることを確認 (`Failed to Use Accounts`)
- Xcode GUIからのアップロードが必要

### Phase 7: GitHub
- リポジトリ作成: https://github.com/shiozaki-new/SyunAI
- 初期コミット完了

## 修正理由
- actool問題: CoreSimulatorのFIFOハンドシェイク失敗はシステム再起動で解決する既知問題。Asset Catalogを除外してarchiveを通した
- Distribution証明書: CLI経由でのexportにはXcodeにApple IDが登録されている必要がある。Xcode GUIからの操作が必要

## 残課題
1. Mac再起動後にAsset Catalog付きで再archive
2. Xcode OrganizerからApp Store Connectへアップロード
3. TestFlightビルドの配布確認
