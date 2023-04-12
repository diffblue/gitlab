# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::WorkspacesController, feature_category: :remote_development do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  shared_examples 'remote development feature flag' do |feature_flag_enabled, expected_status|
    before do
      stub_licensed_features(remote_development: true)
      stub_feature_flags(remote_development_feature_flag: feature_flag_enabled)
    end

    describe 'GET #index' do
      it 'responds with the expected status' do
        get :index

        expect(response).to have_gitlab_http_status(expected_status)
      end
    end
  end

  context 'with remote development feature flag' do
    it_behaves_like 'remote development feature flag', true, :ok
    it_behaves_like 'remote development feature flag', false, :not_found
  end

  context 'with remote development not licensed' do
    before do
      stub_licensed_features(remote_development: false)
    end

    describe 'GET #index' do
      it 'responds with the not found status' do
        get :index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
