require "bundler/gem_tasks"

require "rake/extensiontask"
require "rake/testtask"

task :build => :compile

Rake::ExtensionTask.new("calc") do |ext|
  ext.lib_dir = "lib/calc"
end

Rake::TestTask.new do |t|
  t.pattern = "test/test_*.rb"
  t.libs << "test"
end

task test: :compile
task default: :test

task :indent do
  system("indent -kr -l95 -nut -nce ext/calc/*.[hc]")
  system("rm ext/calc/*.[hc]~")
end
