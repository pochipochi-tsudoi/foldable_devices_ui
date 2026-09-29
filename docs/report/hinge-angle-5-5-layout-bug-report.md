# ヒンジ角度 180° 時に 5:5 レイアウトに切り替わらない不具合調査レポート

## 概要

`DeviceWidth.updateScreen()` を使用した際、`isLimited` の値に関わらず、大画面状態で常に 3:7 のレイアウトが表示され、5:5（等分）に切り替わらない不具合が報告されている。

## 期待される動作

| 画面幅 | `isLimited` | 角度 | 期待されるレイアウト |
|--------|-------------|------|----------------------|
| 狭い   | 任意        | 任意 | `leftWidget` のみ    |
| 広い   | `false`     | 任意 | 5:5                  |
| 広い   | `true`      | < 170° | 3:7              |
| 広い   | `true`      | >= 170° | 5:5             |

## 実際の動作

| 画面幅 | `isLimited` | 角度 | 実際のレイアウト |
|--------|-------------|------|------------------|
| 広い   | `false`     | 任意 | **3:7** （5:5 にならない） |
| 広い   | `true`      | < 170° | 3:7          |
| 広い   | `true`      | >= 170° | 5:5         |

つまり、`isLimited: false` の場合でも 3:7 が表示されてしまう。

## 根本原因

`lib/src/controller/width.dart` の `updateScreen` メソッド内のレイアウト分岐に論理ミスがある。

```dart
if (isLimited && angle >= angleThreshold) {
  return Row(
    children: [
      Expanded(child: rowWidgetItem.leftWidget),
      Expanded(child: rowWidgetItem.rightWidget),
    ],
  );
}

return Row(
  children: [
    Expanded(flex: 3, child: rowWidgetItem.leftWidget),
    Expanded(flex: 7, child: rowWidgetItem.rightWidget),
  ],
);
```

この分岐では：
- `isLimited: true` かつ `angle >= angleThreshold` の場合のみ 5:5
- それ以外のすべてのケースで 3:7

したがって、`isLimited: false` の場合、条件 `isLimited && angle >= angleThreshold` は常に偽となり、必ず 3:7 の `return` に到達してしまう。

本来 `isLimited: false` の場合は、元の幅ベースの動作（広い画面で 5:5）を維持すべきである。

## 修正方針

分岐条件を逆にし、`isLimited: true` かつ角度が閾値未満の場合のみ 3:7 を返し、それ以外は 5:5 を返すようにする。

```dart
if (isLimited && angle < angleThreshold) {
  return Row(
    children: [
      Expanded(flex: 3, child: rowWidgetItem.leftWidget),
      Expanded(flex: 7, child: rowWidgetItem.rightWidget),
    ],
  );
}

return Row(
  children: [
    Expanded(child: rowWidgetItem.leftWidget),
    Expanded(child: rowWidgetItem.rightWidget),
  ],
);
```

これにより：
- `isLimited: false` → 広い画面で常に 5:5（元の動作に戻る）
- `isLimited: true`、角度 < 閾値 → 3:7
- `isLimited: true`、角度 >= 閾値 → 5:5

## 補足：ネイティブ角度取得について

本不具合は Dart 側の論理ミスが主因である。ただし、修正後も以下の環境では角度が 0.0 のままとなり、`isLimited: true` 時に 3:7 から切り替わらない可能性がある：

- **iOS**: `UIHingeInteraction` は iOS 27.1 以降の API。未満の実機 / シミュレータでは角度を取得できない。
- **Android**: `TYPE_HINGE_ANGLE` センサーは対応端末にしか存在しない。非対応端末や通常エミュレータでは 0.0 のまま。

これは別の問題であり、本レポートの主題（`isLimited: false` でも 3:7 になる）とは区別される。

## 確認手順

1. `example/lib/main.dart` で `isLimited: false` を指定して実行。
2. 広い画面状態にする。
3. 5:5 になれば Dart 側の論理ミスが修正されたことになる。
4. `isLimited: true` にして角度を変化させ、170° 未満で 3:7、170° 以上で 5:5 になることを確認。

## 推奨される対応

1. `lib/src/controller/width.dart` の分岐条件を修正。
2. ネイティブ側の角度取得が正しく動作しているか、別途ログを追加して検証。
3. 対応端末でない場合のフォールバック動作をドキュメント化。

## 反省

本不具合を生んだ `lib/src/controller/width.dart` の変更は、私が実装したものである。

### なぜこのミスが生まれたか

1. **既存動作の理解不足**: 元の `DeviceWidth.updateScreen()` は、画面幅が閾値以上の場合に 5:5 の `Row` を返していた。これを「角度が 180° のときだけ 5:5 にしたい」という要望で上書く際に、元の 5:5 フォールバック動作を保持すべきだったが、見落とした。

2. **新機能追加時の後方互換性の無視**: `isLimited` という新しいオプションを追加した際に、`false` の場合の既存動作を明示的にテストせず、新しい 3:7 ロジックがデフォルト路径になってしまった。

3. **条件分岐の方向を誤認**: 「角度が閾値以上なら 5:5」と考えて `if (isLimited && angle >= threshold)` と書いたが、これでは `isLimited: false` の場合に 5:5 路径が全く実行されなくなる。正しくは「`isLimited` かつ角度が閾値未満なら 3:7、それ以外は 5:5」とすべきだった。

4. **検証不足**: 変更後に `isLimited: false` のケースを確認せず、ユーザーからの指摘で初めて気づいた。

### 今後の注意点

- 既存 API のデフォルト動作を変更する際は、後方互換性を意識し、明示的にテストケースを追加する。
- 新しいオプションを導入する際は、`true` / `false` 両方の挙動を確認する。
- レイアウト分岐など視覚的に確認しやすい部分については、変更直後に example アプリで両方の状態を目視確認する。
- ユーザーからの報告を受けた際は、まず自分の実装したコードの論理ミスを疑い、ネイティブ側や外部要因に結論を急がない。

## 修正履歴

- `lib/src/controller/width.dart` の分岐条件を `isLimited && angle < angleThreshold` に修正。これにより `isLimited: false` 時は元の 5:5 動作に戻り、`isLimited: true` 時は角度に応じて 3:7 / 5:5 が切り替わるようになった。
