require 'singleton'
module BrighterPlanet
  class Metadata
    class Data1Authority
      include ::Singleton
      def authority?(method_id)
        return unless ::Rails.env.production? and brighter_planet_server?
        respond_to? method_id
      end
      def resources
        ::Dir[::File.expand_path(::File.join(::File.dirname($LOAD_PATH.grep(%r{earth}).sort_by { |path| path.length }.first), 'lib', 'earth', '**', '*.rb'))].select { |f| ::File.read(f) =~ /class [\:A-Za-z0-9]+ < ActiveRecord::Base/ }.map { |path| ::File.basename(path, '.rb').camelcase }.sort
      end
      def datasets
        ::Dir[::File.expand_path(::File.join(::Rails.root, 'app', 'models', '**', '*.rb'))].select { |f| ::File.read(f) =~ /class [\:A-Za-z0-9]+ < Dataset/ }.map { |path| ::File.basename(path, '.rb').camelcase }.sort
      end
      private
      def brighter_planet_server?
        require 'brighter_planet_deploy'
        ::BrighterPlanet.deploy.servers.me.service == 'ReferenceDataService'
      rescue ::Exception
        false
      end
    end
  end
end
