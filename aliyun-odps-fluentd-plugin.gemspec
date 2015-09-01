# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "aliyun-odps-fluentd-plugin"
  gem.description = "Aliyun ODPS output plugin for Fluentd event collector"
  gem.license     = "Apache-2.0"
  gem.homepage    = "http://gitlab.alibaba-inc.com/aliopensource/aliyun-odps-fluentd-plugin"
  gem.summary     = gem.description
  gem.version     = File.read("VERSION").strip
  gem.authors     = [""]
  gem.email       = ""
  gem.has_rdoc    = false
  #gem.platform    = Gem::Platform::RUBY
  gem.files       = `git ls-files`.split("\n")
  gem.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency "fluentd", [">= 0.10.49", "< 2"]
  gem.add_dependency "protobuf", "~> 3.5.1"
  gem.add_dependency "yajl-ruby", "~> 1.0"
  gem.add_dependency "fluent-mixin-config-placeholders", ">= 0.3.0"
  gem.add_development_dependency "rake", ">= 0.9.2"
  gem.add_development_dependency "flexmock", ">= 1.2.0"
  gem.add_development_dependency "test-unit", ">= 3.0.8"
end
