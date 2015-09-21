begin
  require 'rspec/core/rake_task'
  require 'rubocop/rake_task'
rescue LoadError => e
  warn e
end

RuboCop::RakeTask.new if defined?(RuboCop)
RSpec::Core::RakeTask.new if defined?(RSpec)

task default: [:rubocop, :spec]
