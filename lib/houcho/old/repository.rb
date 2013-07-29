module Houcho
  module Repository
    module_function

    def init
      templates = File.expand_path("#{File.dirname(__FILE__)}/../../templates")

      %W{conf role spec}.each do |d|
        FileUtils.cp_r("#{templates}/#{d}", d) unless Dir.exist?(d)
      end

      File.symlink('./conf/rspec.conf', './.rspec') unless File.exists? '.rspec'

      # `git init; git add .; git commit ...` などはきちんと分割して system 関数を使い、終了コードをチェックしながら実行する
      #  * 途中でどれか失敗したらどうするの？
      [
        "git init",
        "git add .",
        "git commit -a -m 'initialized houcho repository'",
      ].each do |git_operation|
        system(git_operation)
      end
    end
  end
end
