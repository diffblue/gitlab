# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates feature flag', :js, feature_category: :feature_flags do
  include FeatureFlagHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  context 'when creates without changing scopes' do
    before do
      visit(new_project_feature_flag_path(project))
      set_feature_flag_info('ci_live_trace', 'For live trace')
      click_button 'Create feature flag'
      expect(page).to have_current_path(project_feature_flags_path(project))
    end

    it 'records audit event' do
      visit(project_audit_events_path(project))

      expect(page).to have_text("Created feature flag ci_live_trace with description \"For live trace\".")
    end
  end

  private

  def set_feature_flag_info(name, description)
    fill_in 'Name', with: name
    fill_in 'Description', with: description
  end
end
