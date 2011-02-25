require 'singleton'
module BrighterPlanet
  class Metadata
    class Data1Authority
      include ::Singleton
      def authority?(universe, method_id)
        return unless universe == 'data1_production'
        respond_to? method_id
      end
      def resources
        ::Dir[::File.expand_path(::File.join(::File.dirname(::Gem.required_location('earth', 'earth.rb')), 'earth', '**', '*.rb'))].select { |f| ::File.read(f) =~ /class [\:A-Za-z0-9]+ < ActiveRecord::Base/ }.map { |path| ::File.basename(path, '.rb').camelcase }.sort
      end
      def datasets
        ::Dir[::File.expand_path(::File.join(::Rails.root, 'app', 'models', '**', '*.rb'))].select { |f| ::File.read(f) =~ /class [\:A-Za-z0-9]+ < Dataset/ }.map { |path| ::File.basename(path, '.rb').camelcase }.sort
      end
    end
  end
end
