# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CountryStatesController, feature_category: :shared do
  describe 'GET #index' do
    it 'returns a list of states as json' do
      country = 'NL'
      get :index, params: { country: country }

      expected_json = World.states_for_country(country).to_json

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to eq(expected_json)
    end

    it 'returns "null" when the provided country is not found' do
      country = 'NLX'
      get :index, params: { country: country }

      expect(response).to have_gitlab_http_status(:not_found)
      expect(response.body).to eq("null")
    end
  end
end
