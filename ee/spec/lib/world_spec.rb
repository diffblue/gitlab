# frozen_string_literal: true

require 'spec_helper'

RSpec.describe World do
  describe '.all_countries' do
    it 'does not return countries that are in the denied list' do
      result = described_class.all_countries

      expect(result.map(&:name)).not_to include(*World::DENYLIST)
    end
  end

  describe '.countries_for_select' do
    it 'returns list of country name and iso_code in alphabetical format' do
      result = described_class.countries_for_select

      expect(result.first).to eq(%w[Afghanistan AF 🇦🇫 93])
    end
  end

  describe '.states_for_country' do
    it 'returns a list of state names for a country in alphabetical order' do
      result = described_class.states_for_country('NL')

      expect(result.first).to eq(%w[Drenthe DR])
    end

    it 'returns nil when given country cannot be found' do
      result = described_class.states_for_country('NLX')

      expect(result).to be_nil
    end

    it 'excludes blocked states from the list' do
      country_code = 'UA' # Ukraine
      states = described_class.states_for_country(country_code)

      expect(states.keys).not_to include(*World::STATE_DENYLIST_FOR_COUNTRY[country_code])
    end
  end

  describe '.alpha3_from_alpha2' do
    it 'returns the three letter abbreviated country name' do
      result = described_class.alpha3_from_alpha2('NL')

      expect(result).to eq('NLD')
    end

    it 'returns nil when given country cannot be found' do
      result = described_class.alpha3_from_alpha2('NLX')

      expect(result).to be_nil
    end
  end
end
