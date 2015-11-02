require "bundler/gem_tasks"

require "rake/extensiontask"

task :build => :compile

Rake::ExtensionTask.new("calc") do |ext|
  ext.lib_dir = "lib/calc"
end
