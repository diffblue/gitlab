# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/merge_requests/_suggested_reviewers_settings',
  feature_category: :code_review_workflow do
  let_it_be(:user) { build(:user) }
  let_it_be(:project) { build(:project) }

  before do
    assign(:project, project)

    allow(view).to receive(:expanded).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
    allow(project).to receive(:suggested_reviewers_available?).and_return(true)
  end

  context 'when user can create access tokens' do
    before do
      allow(user).to receive(:can?).with(:create_resource_access_tokens, project).and_return(true)
    end

    it 'renders the settings title', :aggregate_failures do
      render

      expect(rendered).to have_content 'Suggested reviewers'
      expect(rendered).to have_content "Get suggestions for reviewers based on GitLab's machine learning tool."
    end

    it 'renders the settings form', :aggregate_failures do
      expect(view).to receive(:gitlab_ui_form_for)
                        .with(project, a_hash_including(url: project_settings_merge_requests_path(project)))
                        .and_call_original

      render

      expect(rendered).to have_css('input[id=project_project_setting_attributes_suggested_reviewers_enabled]')
    end
  end

  context 'when user cannot create access tokens' do
    before do
      allow(user).to receive(:can?).with(:create_resource_access_tokens, project).and_return(false)
    end

    it 'does not render the settings section' do
      render

      expect(rendered).not_to have_content 'Suggested reviewers'
    end
  end
end
