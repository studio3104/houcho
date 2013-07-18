# Houcho
- wrapping to execute serverspec

## Install and Initialize
- install houcho from ruby gems

  ```sh
  $ gem install houcho
  ```

- make working directory and initialize.
  - このディレクトリ配下にrole情報やspecなどが蓄積されます。
  - `houcho init` `git init`されます。
  
  ```sh
$ mkdir houcho-repo
$ cd houcho-repo
$ houcho init
  ```

## Simple Usage
- example of the most simplest use case

  ```sh
  $ houcho spec exec --specs houcho_sample --hosts test.studio3104.com 
  ```

  - run `houcho_sample_spec.rb` ro `test.studio3104.com`
  - arguments of `--specs` and `--hosts` are able to specify multiple space-delimited.
  - argument of `--specs` is able to specify exception of `_spec.rb`, and relative path from `spec/` under working directory.

## Create Role, Run Role
よく使う組み合わせをroleとして定義しておくことが出来ます。

- create role at first.

  ```sh
  $ houcho role create studio3104::www
  ```

- attach a host to role just created.

  ```sh
  $ houcho host attach www01.studio3104.com studio3104::www
  $ houcho host attach www02.studio3104.com studio3104::www
  ```
    
- attach a spec to role.
- argument is able to specify exception of `_spec.rb`, and relative path from `spec/` under working directory same as simple usage.
    
  ```sh
  $ houcho spec attach houcho_sample studio3104::www
  ```

- show details of a role just created.

  ```sh
$ houcho role details studio3104::www
studio3104::www

   [host]
   ├─ www01.studio3104.com
   └─ www02.studio3104.com

   [spec]
   └─ houcho_sample
  ```

- execute role.
- it can specify multiple space-delimited.
  
  ```sh
  $ houcho spec exec --roles studio3104::www
  ```
  
- it is also possible to use regular expressions.
  
  ```sh
  $ houcho spec exec --roles studio3104.+
  ```


## Include CloudForecast's yaml file
houcho can load yaml of CloudForecast, and attach to the role defined.

- install yaml of CloudForecast to `role/cloudforecast/` under working directory.
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
- write test. test. test..............
- `details` is strange. fix. fix. fix...
