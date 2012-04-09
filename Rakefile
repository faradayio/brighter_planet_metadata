require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

task :fallbacks do
  require_relative 'lib/brighter_planet_metadata'
  fallbacks = BrighterPlanet::Metadata::LIVE_URL.inject({}) do |memo, (k, _)|
    if BrighterPlanet.metadata.respond_to?(k)
      memo[k] = BrighterPlanet.metadata.send k
    else
      parts = k.split('_') # rail_trips_options => rail, trips, options
      method_id = parts.pop
      arg = parts.join('_')
      memo[k] = BrighterPlanet.metadata.send method_id, arg
    end
    memo
  end
  File.open(File.expand_path('../lib/brighter_planet_metadata/fallbacks.json', __FILE__), 'w') do |f|
    f.write MultiJson.encode(fallbacks)
  end
end
