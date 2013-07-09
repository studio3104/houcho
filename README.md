# Houcho
- wrapping to execute serverspec

## Install and Initialize
- git cloneして、bin/にPATHを通します。

  ```sh
$ git clone git://github.com/studio3104/houcho.git
$ echo PATH=`pwd`'/houcho/bin:$PATH' >> ~/.bachrc
  ```

- 作業ディレクトリを作成し、イニシャライズします。
  - このディレクトリ配下にrole情報やspecなどが蓄積されます。
  - `houcho init`すると`git init`されます。
  
  ```sh
$ mkdir houcho-repo
$ cd houcho-repo
$ houcho init
  ```

## Simple Usage
- もっともシンプルな使い方の例。

  ```sh
$ houcho spec exec --specs houcho_sample --hosts test.studio3104.com 
  ```

  - `test.studio3104.com`に`houcho_sample_spec.rb`を実行します。
  - `--specs`,`--hosts`の引数は、スペース区切りで複数指定が可能です。
  - `--specs`の引数は、作業ディレクトリの`spec/`からの相対パスで、`_spec.rb`を除いて指定します。
  
## Create Role, Run Role
よく使う組み合わせをroleとして定義しておくことが出来ます。

- まずはroleの作成。

  - role名はフリーワードでokです。

    ```sh
$ houcho role create studio3104::www
    ```
  
  - 作成したroleにホストをattachします。
    - TODO: 複数指定出来るようにする。
  
    ```sh
$ houcho host attach www01.studio3104.com studio3104::www
$ houcho host attach www02.studio3104.com studio3104::www
    ```
    
  - specをattachします。
    - TODO: 複数指定出来るようにする。
  - simple usageと同じように、作業ディレクトリの`spec/`からの相対パスで、`_spec.rb`を除いて指定します。
    
    ```sh
$ houcho spec attach houcho_sample studio3104::www
    ```

- 作成したroleの内容を確認します。

  ```sh
$ houcho role details studio3104::www
studio3104::www

   [host]
   ├─ www01.studio3104.com
   └─ www02.studio3104.com

   [spec]
   └─ houcho_sample
  ```

- roleを実行します。
  - 複数指定が可能です。
  
  ```sh
$ houcho spec exec --roles studio3104::www
  ```
  
  - 正規表現を使うことも出来ます。
  
  ```sh
$ houcho spec exec --roles studio3104.+
  ```
  

## Include CloudForecast's yaml file
cloudoforecastのyamlを読み込み、定義済みのオリジナルroleにattach出来ます。

- cloudforecastのyamlを、`role/cloudforecast/`に設置します。
  - 拡張子を`yaml`にしておく必要があります。
  
- cloudforecastのyamlを読み込みます。(例では`role/cloudforecast/houcho_sample.yaml`を読み込んでいます。)
  - yamlを置き換えるたびに実行してください。毎回実行する必要はありません。
  
  ```sh
$ houcho cfrole configure
$ houcho cfrole show
houcho::author::studio3104
$ houcho cfrole details houcho::author::studio3104
[host(s)]
studio3104.test
studio3105.test
studio3106.test
studio3107.test
studio3108.test
studio3109.test
studio3110.test
  ```
    
- cloudforecastから読み込んだroleを、定義済みのオリジナルroleにattachします。
  - TODO: 複数指定出来るようにする。

  ```sh
$ houcho cfrole attach houcho::author::studio3104 studio3104::www
$ houcho role details studio3104::www
studio3104::www

   [host]
   ├─ www01.studio3104.com
   └─ www02.studio3104.com

   [spec]
   └─ houcho_sample

   [cloudforecast's]
      houcho::author::studio3104
         [host]
         ├─ studio3104.test
         ├─ studio3105.test
         ├─ studio3106.test
         ├─ studio3107.test
         ├─ studio3108.test
         ├─ studio3109.test
         └─ studio3110.test
  ```
  
## Applied Usage
- specを修正したときに、該当のspecが関連付けられているホストを適当にサンプリングして実行する。
  - 複数指定可能。
  - `--sample-host-count`でサンプル数を指定。(default: 5)
  - simple usageと同じように、作業ディレクトリの`spec/`からの相対パスで、`_spec.rb`を除いて指定します。
  
  ```sh
$ houcho spec check houcho_sample hogehogechan
7 examples, 7 failures  studio3109.test, spec/houcho_sample_spec.rb
7 examples, 7 failures  studio3110.test, spec/houcho_sample_spec.rb
7 examples, 7 failures  www02.studio3104.com, spec/houcho_sample_spec.rb
7 examples, 7 failures  studio3105.test, spec/houcho_sample_spec.rb
7 examples, 7 failures  studio3104.test, spec/houcho_sample_spec.rb
hogehogechan has not attached to any roles
  ```

- cloudforecastのroleに含まれている一部のホストを実行対象から外す。

  ```sh
$ houcho host ignore studio3109.test
$ houcho role details studio3104::www
studio3104::www

   [host]
   ├─ www01.studio3104.com
   └─ www02.studio3104.com

   [spec]
   └─ houcho_sample

   [cloudforecast's]
      houcho::author::studio3104
         [host]
         ├─ <ignored>studio3109.test</ignored>
         ├─ studio3104.test
         ├─ studio3105.test
         ├─ studio3106.test
         ├─ studio3107.test
         ├─ studio3108.test
         └─ studio3110.test
  ```

## TODO
- testがない
- attach|detachの引数を複数取れるようにする
- host ignore|disignoreはなにやら変なので他のやりかた考える
  - 引数を複数取れるようにもする
  - disignoreって英語として変
  - include|excludeにすれば実装はそのままでいいかな・・・
