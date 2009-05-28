begin
  require 'rdoc/task'
rescue LoadError
  require 'rake/rdoctask'
  if !Rake.application.options.silent
    STDERR.puts "*** Install the RDoc 2.X gem for nicer docs" 
  end
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = "build/rdoc"
end

