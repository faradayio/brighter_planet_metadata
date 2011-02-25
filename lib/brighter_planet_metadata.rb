require 'cache_method'

module BrighterPlanet
  autoload :Metadata, 'brighter_planet_metadata/metadata'
  def self.metadata
    Metadata.instance
  end
end

# sabshere 2/2/11 in case we ever want to define these directly on BrighterPlanet
# %w{
#   datasets
#   emitters
#   certified_emitters
#   resources
# }.each do |method_id|
#   eval %{
#     def self.#{method_id}
#       Metadata.instance.#{method_id}
#     end
#   }
# end
