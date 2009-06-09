begin
  require 'rdoc/task'
rescue LoadError
  require 'rake/rdoctask'
  if !Rake.application.options.silent
    STDERR.puts "*** `gem install rdoc` for nicer docs" 
  end
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "LICENCE", "lib/**/*.rb")
  rd.rdoc_dir = "build/rdoc"
end

