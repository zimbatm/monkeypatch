require 'rake/gempackagetask'
require 'monkeypatch'

spec = Gem::Specification.new do |s|
  s.name = 'monkeypatch'
  s.version = MonkeyPatch::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "Monkey patching made safe(er)"
  s.homepage = "http://github.com/zimbatm/ruby-monkeypatch"
  s.description = "Provides a mechanism to avoid patch collision. It's also useful to tell if your project is using monkeypatching or not."
  s.authors = ["zimbatm"]
  s.email = "zimbatm@oree.ch"
  s.has_rdoc = true
  s.files = FileList['README.rdoc', 'Rakefile', 'lib/*', 'test/*', 'task/*', 'example/*']
  s.test_files = FileList['test/test*.rb']
end

file "ruby-monkeypatch.gemspec" do |t|
  File.open(t.name, 'w') do |f|
    f.write(spec.to_ruby)
  end
end

Rake::GemPackageTask.new(spec) do |pkg|
#  pkg.need_zip = true
#  pkg.need_tar = true
end

namespace :gem do
  desc "Updates the ruby-monkeypatch.gemspec file"
  task :spec do
    File.open("ruby-monkeypatch.gemspec", 'w') do |f|
      f.write(spec.to_ruby)
    end
  end
end

