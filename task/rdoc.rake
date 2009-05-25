begin
  require 'rdoc/task'
  RDocTask = RDoc::Task
rescue LoadError
  if !Rake.application.options.silent
    STDERR.puts "*** Install the RDoc 2.X gem for nicer docs" 
  end
  
  require 'rake/rdoctask'
  RDocTask = Rake::RDocTask
end

RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

