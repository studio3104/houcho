# Houcho
- wrapping to execute serverspec
- depends on ruby 1.9.3 later(recommended: 2.0.0 later).

## Install and Initialize
- install houcho from ruby gems

  ```sh
  $ gem install houcho
  ```

- initialize working directory.
  - set houcho repository on directory set environment variable `HOUCHO_ROOT`
  - default: `/etc/houcho`

  ```sh
$ houcho init
$ ls /etc/houcho
houcho.conf  houcho.db  log  outerrole  script  spec
  ```

## Simple Usage
- example of the most simplest use case

  ```sh
  $ houcho spec exec houcho_sample --hosts test.studio3104.com 
  ```

  - run `houcho_sample_spec.rb` to `test.studio3104.com`
  - arguments are able to specify multiple space-delimited.
  - argument of `spec exec` is able to specify exception of `_spec.rb`, and relative path from `spec/` under working directory.

## Create Role, Run Role
Houcho is able to define role of combination to be used well.

- create role at first.

  ```sh
  $ houcho role create studio3104::www
  ```

- attach hosts to role just created.

  ```sh
  $ houcho host attach www01.studio3104.com www02.studio3104.com --roles studio3104::www
  ```
    
- attach specs to role.
- argument is able to specify exception of `_spec.rb`, and relative path from `spec/` under working directory same as simple usage.
    
  ```sh
  $ houcho spec attach houcho_sample houcho_sample2 --roles studio3104::www
  ```

- show details of a role just created.

  ```sh
$ houcho role details studio3104::www
[studio3104::www]
   host
   ├─ www01.studio3104.com
   └─ www02.studio3104.com

   spec
   ├─ houcho_sample
   └─ houcho_sample2
  ```

- execute role.
- it can specify multiple space-delimited.
  
  ```sh
  $ houcho role exec studio3104::www
  ```
  
- it is also possible to use regular expressions.
  
  ```sh
  $ houcho role exec studio3104.+
  ```


## Include CloudForecast's yaml file
Houcho is able to load yaml of CloudForecast, and attach to the role defined.

- install yaml of CloudForecast to `${HOUCHO_ROOT}/outerrole/cloudforecast/` under working directory.
- extension have to be yaml.
  
- load cloudforecast's yaml.
  - run each time you replace the yaml. do not need to run every time.
  
  ```sh
$ houcho outerrole load
$ houcho outerrole list
houcho::author::studio3104
$ houcho cf details houcho::author::studio3104
[houcho::author::studio3104]
   host
   ├─ studio3104.test
   └─ studio3105.test
  ```
    
- attach to the original role defined, the role read from cloudforecast.

  ```sh
$ houcho outerrole attach houcho::author::studio3104 --roles studio3104::www
$ houcho role details studio3104::www
[studio3104::www]
   host
   ├─ www01.studio3104.com
   └─ www02.studio3104.com

   spec
   ├─ houcho_sample
   └─ houcho_sample2
   
   outer role
      houcho::author::studio3104
         host
         ├─ studio3104.test
         └─ studio3105.test
  ```

## Setting Attribute to Role, Outer Role, Host
- houcho is able to set individual attribute.
- For example, you have a spec file like this.

  ```
  require "spec_helper"

  describe file(attr[:httpd_conf]) do
    it { should contain "SSLCompression\soff" }
  end
  ```
  
- set variable `attr[:httpd_conf]` to be evaluated at runtime.

  ```
  $ houcho attr set --target role:studio3104::www --value httpd_conf:/etc/httpd/conf/httpd.conf
  ```  
  
  - args of `--target`'s key can specify `host`, `role`, `outerrole`


## Applied Usage
- at modified specs, run specs by sampling appropriately host.
  - `--sample-host-count` can specifies the number of samples(default: 5)
  - argument is able to specify exception of `_spec.rb`, and relative path from `spec/` under working directory same as simple usage.
  
  ```sh
$ houcho spec check houcho_sample hogehogechan
7 examples, 7 failures  studio3109.test, spec/houcho_sample_spec.rb
7 examples, 7 failures  studio3110.test, spec/houcho_sample_spec.rb
7 examples, 7 failures  www02.studio3104.com, spec/houcho_sample_spec.rb
7 examples, 7 failures  studio3105.test, spec/houcho_sample_spec.rb
7 examples, 7 failures  studio3104.test, spec/houcho_sample_spec.rb
hogehogechan has not attached to any roles
  ```

- Run exclude from the target some hosts that are included in the role of cloudforecast.

  ```sh
$ houcho role exec studio3104::www --exclude-hosts studio3104.test
  ```

## TODO
- write more tests