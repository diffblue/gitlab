# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CountriesController do
  describe 'GET #index' do
    it 'returns list of countries as json' do
      get :index

      expected_json = World.countries_for_select.to_json

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to eq(expected_json)
    end

    it 'does not include list of denied countries' do
      get :index

      # response is returned as [["Afghanistan", "AF"], ["Albania", "AL"], ..]
      resultant_countries = json_response.map {|row| row[0]}

      expect(resultant_countries).not_to include(*World::DENYLIST)
      expect(resultant_countries).not_to include(*World::JH_MARKET)
    end
  end
end
