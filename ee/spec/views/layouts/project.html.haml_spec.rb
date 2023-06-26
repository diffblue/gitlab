# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/project', feature_category: :groups_and_projects do
  let(:user) { build_stubbed(:user) }
  let_it_be(:project) { create(:project, :in_group) }

  before do
    assign(:project, project)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
  end

  context 'when free plan limit alert is present' do
    it 'renders the alert partial' do
      render

      expect(rendered).to render_template('projects/_free_user_cap_alert')
    end
  end

  context 'when code suggestions alert is present' do
    before do
      allow(view).to receive(:show_code_suggestions_alert?).and_return(true)
    end

    it 'renders a alert with links to user profile preferences' do
      render

      expect(rendered).to have_content('Get started with Code Suggestions')
      expect(rendered)
        .to have_link('user profile preferences', href: profile_preferences_path(anchor: 'code-suggestions-settings'))
      help_url = help_page_path(
        'user/project/repository/code_suggestions'
      )
      expect(rendered).to have_link('see the documentation', href: help_url)
      profile_url = profile_preferences_path(anchor: 'code-suggestions-settings')
      expect(rendered).to have_link(s_('CodeSuggestionsAlert|Enable Code Suggestions'), href: profile_url)
    end
  end
end
