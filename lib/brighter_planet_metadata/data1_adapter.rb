require 'singleton'
module BrighterPlanet
  class Metadata
    class Data1Adapter
      include ::Singleton
      def authority?(universe, method_id)
        return unless universe == 'data1_production'
        respond_to? method_id
      end
      def resources
        undifferentiated_resources - beta_resources
      end
      def beta_resources
        undifferentiated_resources.select do |name|
          begin
            "::#{name}::BETA".constantize == true
          rescue ::NameError
            false
          end
        end
      end
      def datasets
        undifferentiated_datasets - beta_datasets
      end
      def beta_datasets
        undifferentiated_datasets.select do |name|
          begin
            "::#{name}::BETA".constantize == true
          rescue ::NameError
            false
          end
        end
      end
      private
      def undifferentiated_resources
        ::Dir[::File.expand_path(::File.join(::File.dirname(::Gem.required_location('earth', 'earth.rb')), 'earth', '**', '*.rb'))].select { |f| ::File.read(f) =~ /class [\:A-Za-z0-9]+ < ActiveRecord::Base/ }.map { |path| ::File.basename(path, '.rb').camelcase }.sort
      end
      def undifferentiated_datasets
        ::Dir[::File.expand_path(::File.join(::Rails.root, 'app', 'models', '**', '*.rb'))].select { |f| ::File.read(f) =~ /class [\:A-Za-z0-9]+ < Dataset/ }.map { |path| ::File.basename(path, '.rb').camelcase }.sort
      end
    end
  end
end
