#require 'bundler/gem_tasks'
require "rake"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w(-c)
end

task :default => :spec
task :test => :spec