# SyunAI Release Status

## v2.0.0 無料運用版

### 完了項目
- [x] Google AI Studio / Gemini API 依存の完全廃止
- [x] API キー入力 UI・Keychain 管理の削除
- [x] llama.cpp (b8664) XCFramework の組み込み
- [x] ローカル推論サービス (LocalLLMService) の実装
- [x] モデルダウンロードマネージャー (ModelManager) の実装
- [x] ローカルユーティリティ (日時・計算・単位変換) の実装
- [x] Watch → iPhone 推論中継 (WatchConnectivity) の実装
- [x] iPhone 側モデル準備 UI の実装
- [x] Watch 側接続状態・モデル状態表示の実装
- [x] オンボーディング画面の v2 対応
- [x] iPhone ターゲット ビルド成功
- [x] Watch ターゲット ビルド成功
- [x] ドキュメント更新

### 未完了項目
- [ ] Gemma 4 E2B GGUF の公開確認と切替
- [ ] 実機でのモデルダウンロード・推論テスト
- [ ] Mac 再起動後に Asset Catalog 付きで再 archive
- [ ] Xcode Organizer から TestFlight アップロード
- [ ] TestFlight ビルド配布確認

### Gemma 4 E2B ブロッカー
- 2026-04-05 時点で GGUF 形式での公開を確認できず
- 暫定として Gemma 2 2B IT (Q4_K_M) を設定済み
- `Constants.swift` の `modelDownloadURL` と `modelFileName` を差し替えれば即切替可能

### 無料運用の根拠
- 推論はすべて iPhone 上のローカル llama.cpp で実行
- 外部 API 通信なし（モデル初回ダウンロードを除く）
- API キー不要
- ユーザー課金ゼロ

### 人間の操作が必要な箇所
1. **Mac 再起動** - CoreSimulator/actool の修復に必要
2. **Xcode の Accounts 設定確認** - Apple ID 登録が必要
3. **実機テスト** - ローカル推論の性能・安定性確認
4. **Xcode Organizer からアップロード** - Distribution 証明書の自動作成に Xcode GUI が必要

---

## v1.0.0 (旧バージョン)

### 完了項目
- [x] プロジェクト構造設計・作成
- [x] iPhone/watchOS 全ソースコード実装
- [x] Google AI Studio (Gemma) API統合
- [x] WatchConnectivity設定同期
- [x] Keychain APIキー管理
- [x] オンボーディングUI (iPhone)
- [x] クイックプロンプト機能 (Watch)
- [x] XcodeGen project.yml 作成
- [x] Bundle ID登録 (Developer Portal)
- [x] App Store Connectアプリ登録 (ID: 6761652986)
- [x] TestFlight内部テストグループ作成
- [x] テスター追加 (skstudio8004430@gmail.com)
- [x] Archive成功 (Assets除外状態)
- [x] GitHubリポジトリ作成・push
- [x] Info.plist (ITSAppUsesNonExemptEncryption: false 設定済)
- [x] アプリアイコン作成 (1024x1024)
- [x] Asset Catalog設定を repo 上で復帰 (iPhone / Watch)
