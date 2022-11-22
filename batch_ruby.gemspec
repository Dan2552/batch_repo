lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "batch_repo/version"

Gem::Specification.new do |spec|
  spec.name          = "batch_repo"
  spec.version       = BatchRepo::VERSION
  spec.authors       = ["Daniel Inkpen"]
  spec.email         = ["dan2552@gmail.com"]

  spec.summary       = ""
  spec.description   = ""
  spec.homepage      = "https://github.com/Dan2552/batch_repo"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "file-transaction", "~> 1.0.0"
  spec.add_dependency "thor", "~> 1.1.0"
end
