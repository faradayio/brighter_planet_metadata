require 'singleton'
module BrighterPlanet
  class Metadata
    class Cm1Authority
      include ::Singleton
      def authority?(method_id)
        return unless defined?(::Rails) and ::Rails.env.production? and brighter_planet_server?
        method_id = method_id.to_s
        if method_id == 'certified_emitters'
          ::Rails.application.certified?
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
          memo[p] = ::File.read(::File.join(::Rails.root, 'app', 'views', 'protocols', 'names', "_#{p}.html.erb")).strip
          memo
        end
      end
      private
      def brighter_planet_server?
        require 'brighter_planet_deploy'
        ::BrighterPlanet.deploy.servers.me.service == 'EmissionEstimateService'
      rescue ::Exception
        false
      end
    end
  end
end
