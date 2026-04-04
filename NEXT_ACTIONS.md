# v2.0.0 次のアクション

## 1. Gemma 4 E2B GGUF の確認
Gemma 4 E2B の GGUF 形式モデルが公開されているか確認する。
公開されていれば、以下の2行を変更するだけで切替可能:
```swift
// Shared/Constants.swift
static let modelFileName = "gemma-4-e2b-it-Q4_K_M.gguf"
static let modelDownloadURL = "https://huggingface.co/.../gemma-4-e2b-it-Q4_K_M.gguf"
```

## 2. Mac を再起動する
CoreSimulator の問題で Asset Catalog がビルドできないため、再起動が必要。

## 3. 実機テスト
モデルダウンロードと推論を実機で確認する:
- iPhone でモデルダウンロード（Wi-Fi 推奨、約1.5GB）
- モデル読み込み成功の確認
- Watch から質問して応答が返るか確認
- ローカルユーティリティ（日時・計算）の動作確認
- 推論速度の確認（Gemma 2 2B は iPhone 15 Pro で数秒程度を想定）

## 4. ターミナルで再 archive
```bash
cd /Users/siojakieiseuke/SyunAI
/opt/homebrew/bin/xcodegen generate

xcodebuild archive \
  -project SyunAI.xcodeproj \
  -scheme "SyunAI iPhone" \
  -destination 'generic/platform=iOS' \
  -archivePath ~/Desktop/SyunAI-v2.xcarchive \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=M878XBQ25U \
  CODE_SIGN_STYLE=Automatic
```

## 5. Xcode Organizer からアップロード
1. Xcode → Window → Organizer
2. SyunAI v2 の archive を選択
3. 「Distribute App」→「App Store Connect」
4. アップロード完了後、TestFlight で自動配布される

## 補足
- `Frameworks/llama.xcframework` は約 167MB（圧縮時）で git に含まれる
- .gitignore でモデルファイル (`*.gguf`) は除外すること
- 配布時は TestFlight 経由が最も簡単
