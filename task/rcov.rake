begin
  require 'rcov/rcovtask'
  
  Rcov::RcovTask.new do |t|
    t.libs << "test"
    t.test_files = FileList['test/test*.rb']
    t.verbose = true
    t.output_dir = "build/rcov"
  end
  
rescue LoadError
  if !Rake.application.options.silent
    STDERR.puts "*** `gem install rcov` for code coverage" 
  end
end
