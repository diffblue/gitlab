# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates GitHub integration', feature_category: :integrations do
  include_context 'project integration activation'

  context 'without a license' do
    it "is excluded from the integrations index" do
      visit_project_integrations

      expect(page).not_to have_link('GitHub')
    end

    it 'renders 404 when trying to access integration settings directly' do
      visit edit_project_settings_integration_path(project, :github)

      expect(page).to have_gitlab_http_status(:not_found)
    end
  end

  context 'with valid license', :js do
    before do
      stub_licensed_features(github_integration: true)

      visit_project_integration('GitHub')

      fill_in_details
    end

    def fill_in_details
      fill_in "Token", with: "aaaaaaaaaa"
      fill_in "Repository URL", with: 'https://github.com/h5bp/html5-boilerplate'
    end

    it 'activates integration' do
      click_button('Save')

      expect(page).to have_content('GitHub settings saved and active.')
    end

    it 'renders a token field of type `password` for masking input' do
      expect(find('#service_token')['type']).to eq('password')
    end

    context 'with pipelines', :js do
      let(:pipeline) { create(:ci_pipeline) }
      let(:project) { create(:project, ci_pipelines: [pipeline]) }

      it 'tests integration before save' do
        stub_request(:post, "https://api.github.com/repos/h5bp/html5-boilerplate/statuses/#{pipeline.sha}").to_return(
          body: { context: {} }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        click_test_then_save_integration(expect_test_to_fail: false)

        expect(page).to have_content('GitHub settings saved and active.')
      end
    end
  end
end
