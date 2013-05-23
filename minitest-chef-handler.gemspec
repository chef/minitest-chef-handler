# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.authors       = ["David Calavera"]
  gem.email         = ["david.calavera@gmail.com"]
  gem.description   = %q{Run minitest suites after your Chef recipes to check the status of your system.}
  gem.summary       = %q{Run Minitest suites as Chef report handlers}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "minitest-chef-handler"
  gem.require_paths = ["lib"]
  gem.version       = '1.0.1'

  gem.add_dependency('minitest', '~> 4.7.3')
  gem.add_dependency('chef')
  gem.add_dependency('ci_reporter')
  gem.add_development_dependency "rake"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "appraisal"
  gem.add_development_dependency "ffi", ">= 1"
  gem.add_development_dependency "vagrant", ">= 1.1"
  gem.add_development_dependency "berkshelf", ">= 1.3.1"
  gem.add_development_dependency "vagrant-berkshelf"
end
