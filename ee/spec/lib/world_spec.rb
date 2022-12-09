# frozen_string_literal: true

require 'spec_helper'

RSpec.describe World, feature_category: :purchase do
  describe '.country_deny_list' do
    # this spec exists to catch relevant changes in the gem's upstream data
    it 'ensures the items in the country deny list map to real country objects' do
      expect(ISO3166::Country.all.map(&:alpha2) ).to include(*described_class.country_deny_list)
    end
  end

  describe '.supported_countries' do
    let_it_be(:supported_countries) { described_class.supported_countries }

    it 'does not return countries that are in the country deny list' do
      expect(supported_countries.map(&:name)).not_to include(*described_class.country_deny_list)
    end

    # this spec exists to catch relevant changes in the gem's upstream data
    it 'returns exactly 239 countries' do
      expect(supported_countries.count).to eq(239)
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

    describe 'blocked states' do
      let(:country_with_blocked_states) { 'UA' }

      it 'contains Ukraine' do
        # this spec exists to catch relevant changes in the gem's upstream data
        expect(World::STATE_DENYLIST_FOR_COUNTRY.keys).to match_array([country_with_blocked_states])
      end

      it 'ensures blocked states map to real state objects' do
        # this spec exists to catch relevant changes in the gem's upstream data
        country = ISO3166::Country.find_country_by_alpha2(country_with_blocked_states)
        blocked_states = World::STATE_DENYLIST_FOR_COUNTRY[country_with_blocked_states]

        expect(country.subdivisions.map { |_, subdivision| subdivision.name }).to include(*blocked_states)
      end

      it 'excludes blocked states from the list' do
        states = described_class.states_for_country(country_with_blocked_states)

        expect(states.keys).not_to include(*World::STATE_DENYLIST_FOR_COUNTRY[country_with_blocked_states])
      end
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
