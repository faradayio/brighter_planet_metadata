require 'helper'

describe BrighterPlanet::Metadata do
  describe '.refresh' do
    it 'clears the cache' do
      VCR.use_cassette 'emitters', :re_record_interval => 30.days do
        BrighterPlanet.metadata.emitters.should include('Flight')
      end

      # still the old value because it's cached...
      VCR.use_cassette 'new emitters', :record => :once do
        BrighterPlanet.metadata.emitters.should_not include('Dirigible')
        BrighterPlanet.metadata.refresh
        BrighterPlanet.metadata.emitters.should include('Dirigible')
      end
    end
  end
  
  %w{
    certified_emitters
    datasets
    emitters
    protocols
    resources
  }.each do |kind|
    it "fetches #{kind}" do
      VCR.use_cassette kind, :re_record_interval => 30.days do
        BrighterPlanet.metadata.send(kind).should_not be_empty
      end
    end
  end

  it 'fetches options for a flight' do
    VCR.use_cassette 'flight options', :re_record_interval => 30.days do
      BrighterPlanet.metadata.options(:flight).should include('origin_airport')
    end
  end

  it 'fetches options for electricity use' do
    VCR.use_cassette 'electricity use options', :re_record_interval => 30.days do
      BrighterPlanet.metadata.options(:electricity_use).should include('zip_code')
    end
  end

  it 'fetches committees for a flight' do
    VCR.use_cassette 'flight committees', :re_record_interval => 30.days do
      BrighterPlanet.metadata.committees(:flight).should include('energy')
    end
  end

  context 'using fallbacks' do
    use_vcr_cassette '500 error', :record => :new_episodes

    it 'provides emitters' do
      BrighterPlanet.metadata.emitters.should include('AutomobileTrip')
    end
      
    it 'provides resources' do
      BrighterPlanet.metadata.resources.should include('AutomobileMake')
    end
    
    it 'provides datasets' do
      BrighterPlanet.metadata.datasets.should include('AutomobileIndustry')
    end
    
    it 'provides protocols' do
      BrighterPlanet.metadata.protocols.values.should include('The Climate Registry')
    end

    it 'provides options' do
      BrighterPlanet.metadata.options(:flight).should include('origin_airport')
    end

    it 'provides committees' do
      BrighterPlanet.metadata.committees(:flight).should include('energy')
    end
  end
end
