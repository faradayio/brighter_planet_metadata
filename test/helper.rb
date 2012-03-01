require 'rubygems'
require 'bundler'
Bundler.setup
require 'test/unit'
require 'webmock/test_unit'
require 'fileutils'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'brighter_planet_metadata'

class Test::Unit::TestCase
  def setup
    BrighterPlanet.metadata.refresh
    WebMock.enable!
    WebMock.disable_net_connect!
  end
  def teardown
    WebMock.reset!
    WebMock.disable!
  end
end

ENV['BRIGHTER_PLANET_METADATA_DEBUG'] = 'true'
