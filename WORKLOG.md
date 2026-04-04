# SyunAI WORKLOG

## 実施日: 2026-04-05

### v2.0.0 無料運用版への全面改修

#### 目的
- Google AI Studio / Gemini API 依存を完全廃止
- ユーザー API キー入力・課金ゼロで運用可能にする
- ローカル推論（llama.cpp + GGUF モデル）に切り替え
- Apple Watch は UI 専用、iPhone がローカル推論を担当する構成に変更

#### 技術選定
- **ランタイム**: llama.cpp (XCFramework, b8664)
  - ggml-org 公式リリースの `llama.xcframework` を `Frameworks/` に配置
  - mattt/llama.swift の SPM 経由は Xcode SPM バイナリターゲットキャッシュバグで断念
  - ローカル XCFramework で直接リンクに変更し解決
- **モデル**: Gemma 2 2B IT (Q4_K_M GGUF, 約1.5GB)
  - 初回ダウンロード方式（アプリ同梱は App Store サイズ制限で非現実的）
  - Gemma 4 E2B の GGUF が公開され次第、URL 差し替えで切替可能

#### Gemma 4 E2B について
- 第一候補として指定されたが、GGUF 形式での公開状況を確認できず
- アーキテクチャは任意の GGUF モデルに対応する設計にした
- Constants.swift の `modelDownloadURL` と `modelFileName` の2行を変更するだけで切替可能

#### 変更内容

**削除したファイル (3)**
- `iPhoneApp/Services/PhoneKeychainService.swift` - API キー Keychain 管理
- `WatchApp/Services/KeychainService.swift` - Watch 側 Keychain 管理
- `Shared/Models/GemmaModels.swift` - Gemini API リクエスト/レスポンスモデル

**新規作成したファイル (3)**
- `iPhoneApp/Services/LocalLLMService.swift` - llama.cpp ラッパー（モデル読み込み・推論）
- `iPhoneApp/Services/ModelManager.swift` - モデルダウンロード・ライフサイクル管理
- `Shared/LocalUtility.swift` - 日時・計算・単位変換のローカル処理

**新規追加 (1)**
- `Frameworks/llama.xcframework` - llama.cpp b8664 XCFramework (iOS arm64)

**大幅書き換え (8)**
- `project.yml` - SPM 依存削除、XCFramework 参照追加、バージョン 2.0.0
- `Shared/Constants.swift` - API 設定廃止、ローカルモデル設定追加
- `Shared/Models/ChatMessage.swift` - apiMessage プロパティ削除
- `iPhoneApp/Views/PhoneHomeView.swift` - API キー UI 廃止、モデルダウンロード UI
- `iPhoneApp/Services/PhoneConnectivityService.swift` - 推論リクエスト中継
- `iPhoneApp/App/SyunAIApp.swift` - ModelManager 追加
- `WatchApp/ViewModels/WatchChatViewModel.swift` - WC 経由推論リクエスト
- `WatchApp/Services/WatchConnectivityService.swift` - 推論リクエスト送受信
- `WatchApp/Views/WatchHomeView.swift` - API キー表示→接続/モデル状態表示
- `WatchApp/Views/WatchSettingsView.swift` - v2.0.0 表示

#### ビルド結果
- iPhone ターゲット: **BUILD SUCCEEDED**
- Watch ターゲット: **BUILD SUCCEEDED**
- ビルド環境: Xcode 16, macOS, generic/platform=iOS, generic/platform=watchOS

---

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
