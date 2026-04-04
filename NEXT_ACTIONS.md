# 朝やること (3ステップ)

## 1. Macを再起動する
CoreSimulatorの問題でAsset Catalogがビルドできないため、再起動が必要。

## 2. ターミナルで再archive
```bash
cd /Users/siojakieiseuke/SyunAI

# Asset Catalogは repo 上ですでに復帰済み
/opt/homebrew/bin/xcodegen generate

# Archive
xcodebuild archive \
  -project SyunAI.xcodeproj \
  -scheme "SyunAI iPhone" \
  -destination 'generic/platform=iOS' \
  -archivePath ~/Desktop/SyunAI.xcarchive \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=M878XBQ25U \
  CODE_SIGN_STYLE=Automatic
```

### 現在のrepo状態
- `project.yml` は iPhone / Watch 両方で Asset Catalog を含む状態に戻してある
- `WatchApp/Assets.xcassets/` も追加済み
- ただしこの Mac では再起動前に `actool` が iPhone / Watch とも `AssetCatalogSimulatorAgent` 起動失敗で落ちるのを再確認済み

## 3. Xcode Organizerからアップロード
1. Xcode → Window → Organizer
2. SyunAIのarchiveを選択
3. 「Distribute App」→「App Store Connect」
4. アップロード完了後、TestFlightで自動配布される

### 補足
- `xcodebuild -exportArchive` はこの Mac の Xcode に Apple ID アカウントが未登録のため `Failed to Use Accounts` で失敗する
- Distribution証明書の自動作成は Xcode GUI 側で行う前提
