require 'rubygems'
require 'bundler'
Bundler.setup
require 'test/unit'
require 'ruby-debug'
require 'fakeweb'
require 'fakefs/safe'
require 'fileutils'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'brighter_planet_metadata'
class Test::Unit::TestCase
  def setup
    BrighterPlanet.metadata.refresh
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
    Rails.application.certified = false
  end
  def teardown
    FakeFS::FileSystem.clear
    FakeFS.deactivate!
    FakeWeb.allow_net_connect = true
    Rails.application.certified = false
  end
end

require 'singleton'
module Rails
  def self.application
    FakeApplication.instance
  end
  class FakeApplication
    include ::Singleton
    attr_writer :certified
    def certified?
      @certified == true
    end
  end
end
