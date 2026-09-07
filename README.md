# fcitx5-hazkey

Hazkey input method for fcitx5
[Original](https://github.com/7ka-Hiira/hazkey) by 7ka-Hiira

[AzooKeyKanaKanjiConverter](https://github.com/azooKey/AzooKeyKanaKanjiConverter)を利用したIMEです

## ホームページ

[https://hazkey.hiira.dev](https://hazkey.hiira.dev)

## ドキュメント

[https://hazkey.hiira.dev/docs](https://hazkey.hiira.dev/docs)

## インストール

~~[インストールガイド](https://hazkey.hiira.dev/docs/install)~~
~~現在AURと[debianパッケージ](https://github.com/7ka-Hiira/fcitx5-hazkey/releases/latest)が利用できます。~~
現在「[kaede-rs/hazk](https://github.com/kaede-rs/hazk/)」でのインストール手順はビルドのみとなっています。

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

ninjaを利用します。

```sh
git clone --recursive https://github.com/kaede-rs/hazk.git
cd hazkey
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DGGML_VULKAN=OFF -G Ninja ..
ninja
sudo ninja install
```

## 最後に

本プロジェクトは[7ka-Hiira](https://github.com/7ka-Hiira)様によるオリジナル版hazkeyの設計とコードを継承しています。
オリジナルの開発者である**7ka-Hiira**様に深く敬意を表します。

## ライセンス

[MIT License](./LICENSE)
