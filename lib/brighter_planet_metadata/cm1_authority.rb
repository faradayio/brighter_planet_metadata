require 'singleton'
module BrighterPlanet
  class Metadata
    class Cm1Authority
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
        ary = []
        ::ObjectSpace.each_object(::BrighterPlanet::Emitter) do |obj|
          ary.push obj.name.demodulize
        end
        ary
      end
      def certified_emitters
        emitters
      end
      def protocols
        emitters.map(&:constantize).map(&:protocols).flatten.uniq.inject({}) do |memo, p|
          memo[p] = File.new(File.join(Rails.root, 'app', 'views', 'protocols', 'names', "_#{p}.html.erb")).read.strip 
          memo
        end
      end
    end
  end
end
