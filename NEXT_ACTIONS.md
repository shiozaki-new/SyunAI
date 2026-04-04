# 朝やること (3ステップ)

## 1. Macを再起動する
CoreSimulatorの問題でAsset Catalogがビルドできないため、再起動が必要。

## 2. ターミナルで再archive
```bash
cd /Users/siojakieiseuke/SyunAI

# project.ymlのAsset Catalog除外を元に戻す
# (現在xcassetsがexcludeされている)

# Asset Catalogの除外を解除してproject再生成
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

## 3. Xcode Organizerからアップロード
1. Xcode → Window → Organizer
2. SyunAIのarchiveを選択
3. 「Distribute App」→「App Store Connect」
4. アップロード完了後、TestFlightで自動配布される
