% Slide Show Headers

title: Houcho
subtitle: 
author: @studio3104

% Slides Start Here

# What is Houcho?

###  多数のホストに対する serverspec の実行をラップ

### ホストと spec を紐付けてロールとして定義

### 外部のホストの組み合わせ定義を取り込んで扱える

  - CloudForecast
  - Yabitz


# リポジトリの初期化

### Houcho で使うディレクトリを初期化
- 環境変数 `HOUCHO_ROOT` を参照
- `HOUCHO_ROOT` が未定義の場合、`/etc/houcho` が作成される

```sh
$ houcho init
$ ls /etc/houcho
houcho.conf   houcho.db   log   outerrole   script   spec
```

# 制約など

### 実行環境
- Ruby 1.9.3以降じゃないと動きません
  - serverspec は 1.8 をサポートしてますが・・・

### spec ファイル
- /etc/houcho/spec に設置
- _spec.rb で終わるファイル名
- コマンドの引数で渡してあげる場合
  - /etc/houcho/spec からの相対パス
  - _spec.rb をはずす


# シンプルな使い方

#### test.studio3104.com に bose ユーザが存在するかどうかテストする
- atnodes ライクな使い勝手

### spec ファイル

##### /etc/houcho/spec/user-check_spec.rb

```rb
describe user("bose") do
  it { should exist }
end
```

### コマンド

```
$ houcho spec exec user-check --hosts test.studio3104.com
```

- 引数には spec を1つ以上指定
- オプション
  - --hosts ホストを1つ以上指定
  - --dry-run 実行されるコマンドを表示


# ロール1

### ロールの作成

```sh
$ houcho role create user
```

### ホストと spec を関連付ける

```sh
$ houcho host attach test.studio3104.com --roles user
$ houchoc spec attach user-check --roles user
```

### 詳細確認

```sh
$ houcho role details test1
[user]
  host
  └─ test.studio3104.com

  spec
  └─ user-check
```


# ロール2

### ロールを実行

```sh
$ houcho role exec user
```

- 引数には ロール を1つ以上指定
- オプション
  - --dry-run 実行されるコマンドを表示


# CF からホストの組み合わせをLOAD1

### 設定ファイル

##### /etc/houcho/outerrole/cloudforecast/cloudforecast.yaml

```
--- #hoge
servers:
  - label: foo
  config: bar.yaml
  hosts:
    - 192.168.1.10 test01.studio3104.com
    - 192.168.1.11 test02.studio3104.com
    - 192.168.1.12 test03.studio3104.com
```


# CF からホストの組み合わせをLOAD2

### コマンド

```
$ houcho outerrole load
```

### 確認

```
$ houcho outerrole list
hoge::foo::bar
```

```
$ houcho outerrole details hoge::foo::bar
[hoge::foo::bar]
  host
  ├─ test01.studio3104.com
  ├─ test02.studio3104.com
  └─ test03.studio3104.com
```


# Yabitz からホストの組み合わせをLOAD

### 設定

##### /etc/houcho/houcho.conf

```
yabitz:
  host: yabitz.url
  port: 80
```

### コマンド

```
$ houcho outerrole load
```


# ロールに外部のホスト定義を紐付け

### コマンド

```sh
$ houcho outerrole attach hoge::foo::bar --roles user
```

### 確認

```sh
$ houcho role details test1
[user]
  host
  └─ test.studio3104.com

  spec
  └─ user-check

  outer role
    hoge::foo::bar
      host
      ├─ test01.studio3104.com
      ├─ test02.studio3104.com
      └─ test03.studio3104.com
```


# ホストやロールに固有の情報を設定する

### spec ファイル例

```
describe file(attr[:nginx_log_dir]) do
  it { should be_directory }
end
```

### コマンド

```sh
$ houcho attr set nginx_log_dir:/var/log/nginx --target host:test.studio3104.com
```

### 参照優先順位

##### attribute は実行時に評価される

##### attribute は host、外部ホスト定義、ロールにそれぞれ設定可能

##### 優先順位の高い値が設定されていれば上書きされる
- host > outer role > role


# spec ファイルを修正したら

##### 関連付けられたホストをサンプリングして実行する

### コマンド

```sh
$ houcho spec check user-check
```

- オプション
  - --samples サンプリング数を指定(default: 5)
