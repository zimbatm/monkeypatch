require 'rake/gempackagetask'
require 'monkeypatch'

spec = Gem::Specification.new do |s|
  s.name = 'monkeypatch'
  s.version = MonkeyPatch::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "safer code patching at runtime"
  s.homepage = "http://github.com/zimbatm/monkeypatch"
  s.description = "Provides a patch collision detection engine for safer patch application."
  s.authors = ["zimbatm"]
  s.email = "zimbatm@oree.ch"
  s.has_rdoc = true
  s.files = FileList['README.rdoc', 'LICENCE', 'Rakefile', 'lib/*', 'test/*', 'task/*', 'example/*']
  s.test_files = FileList['test/test*.rb']
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.package_dir = "build"
#  pkg.need_zip = true
#  pkg.need_tar = true
end
task :gem => "gem:spec"

namespace :gem do

  spec_name = "monkeypatch.gemspec"
  desc "Updates the #{spec_name} file if VERSION has changed"
  task :spec do
    if !File.exist?(spec_name) ||
      eval(File.read(spec_name)).version.to_s != MonkeyPatch::VERSION
      File.open(spec_name, 'w') do |f|
        f.write(spec.to_ruby)
      end
      STDOUT.puts "*** Gem specification updated ***"
    end
  end
end

