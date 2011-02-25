require 'dnsruby'
module BrighterPlanet
  class Metadata
    module AuthoritativeDnsResolver
      def self.getaddress(domain_name)
        r = ::Dnsruby::Resolver.new(:nameserver => %w{ ns1.easydns.com ns2.easydns.com ns3.easydns.org })
        q = r.query domain_name, ::Dnsruby::Types.A, ::Dnsruby::Classes.IN
        q.answer[0].address.to_s
      end
    end
  end
end
