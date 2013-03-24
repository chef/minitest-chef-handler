require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"
require "appraisal"

Rake::TestTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

task :default do
  sh "rake appraisal:install && rake appraisal spec"
end
