# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CountriesController, feature_category: :shared do
  describe 'GET #index' do
    it 'returns list of countries as json' do
      get :index

      expected_json = World.countries_for_select.to_json

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to eq(expected_json)
    end

    it 'does not include list of denied countries' do
      get :index

      # response is returned as [["Country Name", "Country Code", "Country Flag Emoji", "Dialing Code"], ...]
      resultant_countries = json_response.map { |row| row[0] }

      expect(resultant_countries).not_to include(*World.country_deny_list)
    end

    it 'overrides Ukraine name and adds information about restricted regions' do
      get :index

      # response is returned as [["Country Name", "Country Code", "Country Flag Emoji", "Dialing Code"], ...]
      country_ukraine = json_response.find { |row| row[0].include?('Ukraine') }

      expect(country_ukraine[0]).to eq('Ukraine (except the Crimea, Donetsk, and Luhansk regions)')
    end

    it "updates `Taiwan, Province of China` to `Taiwan`" do
      get :index

      expect(json_response.select { |row, _| row == 'Taiwan' }).not_to be_empty
    end
  end
end
