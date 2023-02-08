# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AutomationsController, type: :request, feature_category: :no_code_automation do
  describe 'GET /:namespace/:project/-/automations' do
    let_it_be(:project) { create(:project) }
    let(:user) { project.first_owner }

    before do
      stub_feature_flags(no_code_automation_mvc: true)
      stub_licensed_features(no_code_automation: true)

      login_as(user)
    end

    shared_examples 'returns not found' do
      it 'returns 404 response' do
        get project_automations_path(project)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'returns 200 response' do
      get project_automations_path(project)

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(no_code_automation_mvc: false)
      end

      it_behaves_like 'returns not found'
    end

    context 'when the feature is unlicensed' do
      before do
        stub_licensed_features(no_code_automation: false)
      end

      it_behaves_like 'returns not found'
    end

    context 'when the feature is unlicensed AND the feature flag is disabled' do
      before do
        stub_feature_flags(no_code_automation_mvc: false)
        stub_licensed_features(no_code_automation: false)
      end

      it_behaves_like 'returns not found'
    end
  end
end
