# fcitx5-hazkey

Hazkey input method for fcitx5

[Original](https://github.com/7ka-Hiira/hazkey) by [7ka-Hiira](https://github.com/7ka-Hiira)

[AzooKeyKanaKanjiConverter](https://github.com/azooKey/AzooKeyKanaKanjiConverter)を利用したIMEです

## ホームページ

[https://hazkey.hiira.dev](https://hazkey.hiira.dev)

## ドキュメント

[https://hazkey.hiira.dev/docs](https://hazkey.hiira.dev/docs)

## インストール

[インストールガイド](https://hazkey.hiira.dev/docs/install)

現在[Debianパッケージ](https://github.com/kaede-rs/hazk/releases/latest)のみが利用できます。

## ビルド

詳細は[ドキュメントのビルドページを参照してください](https://hazkey.hiira.dev/docs/development/build)。

### 依存関係

- Swift >= 6.1
- fcitx5 >= 5.0.4
- Qt >= 6.7 (6.2以降でビルド可能ですが表示が崩れる場合があります)
- CMake >= 3.21 (4.x以降推奨)
- Protobuf >= 3.12
- Ninja
- Gettext

### ソースビルド・インストール手順

JustとNinjaを利用します。

```sh
# ビルド
just configure
just build

# インストール
just install
```

## 最後に

本プロジェクトは[7ka-Hiira](https://github.com/7ka-Hiira)様によるオリジナル版[hazkey](https://github.com/7ka-Hiira/hazkey)の設計とコードを継承しています。

オリジナルの開発者である[7ka-Hiira](https://github.com/7ka-Hiira)様に深く敬意を表します。

## ライセンス

[MIT License](./LICENSE)
