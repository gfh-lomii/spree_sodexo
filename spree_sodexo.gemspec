
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spree_sodexo/version'

Gem::Specification.new do |spec|
  spec.platform      = Gem::Platform::RUBY
  spec.name          = 'spree_sodexo'
  spec.version       = SpreeSodexo::VERSION
  spec.authors       = ['chinoxchen']
  spec.email         = ['chienfu.udp@gmail.com']

  spec.summary       = 'Spree integration with Sodexo'
  spec.description   = 'Spree integration with Sodexo'
  spec.homepage      = 'https://github.com/chinoxchen/spree_sodexo'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spree_version = '>= 4.0.0', '< 5.0'
  spec.add_development_dependency 'spree_dev_tools'
end
