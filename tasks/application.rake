desc 'Start the application'
task :start do
  system "bundle exec thin start"
end
