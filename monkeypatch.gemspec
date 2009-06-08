# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{monkeypatch}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["zimbatm"]
  s.date = %q{2009-06-08}
  s.description = %q{Provides a mechanism to avoid patch collision. It's also useful to tell if your project is using monkeypatching or not.}
  s.email = %q{zimbatm@oree.ch}
  s.files = ["README.rdoc", "Rakefile", "lib/monkeypatch.rb", "test/test_monkeypatch.rb", "task/gem.rake", "task/rcov.rake", "task/rdoc.rake", "task/test.rake", "example/core_ext.rb", "example/ipaddr_range_support.rb", "example/mime_type.rb", "example/process_as_user_ext.rb", "example/sinatra_monkeypatch.rb", "example/uri_user_fix.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/zimbatm/monkeypatch}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Monkey patching made safe(er)}
  s.test_files = ["test/test_monkeypatch.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
