require 'singleton'
module BrighterPlanet
  class Metadata
    class Cm1Adapter
      include ::Singleton
      def authority?(universe, method_id)
        return unless universe == 'cm1_production'
        method_id = method_id.to_s
        if method_id == 'certified_emitters'
          defined?(::Rails) and ::Rails.application.certified?
        else
          respond_to? method_id
        end
      end
      def emitters
        undifferentiated_emitters - beta_emitters
      end
      def beta_emitters
        undifferentiated_emitters.select do |name|
          begin
            "::BrighterPlanet::#{name}::BETA".constantize == true
          rescue ::NameError
            false
          end
        end
      end
      def certified_emitters
        emitters
      end
      private
      def undifferentiated_emitters
        ary = []
        ::ObjectSpace.each_object(::BrighterPlanet::Emitter) do |obj|
          ary.push obj.name.demodulize
        end
        ary
      end
    end
  end
end
