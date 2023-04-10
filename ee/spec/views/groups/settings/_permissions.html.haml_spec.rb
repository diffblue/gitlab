# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups/settings/_permissions.html.haml', :saas, feature_category: :code_suggestions do
  context 'for code suggestions' do
    before do
      group = build(:group, namespace_settings: build(:namespace_settings))
      assign(:group, group)
      allow(view).to receive(:can?).and_return(true)
      allow(view).to receive(:current_user).and_return(build(:user))
    end

    it 'renders nothing' do
      allow(view).to receive(:ai_assist_ui_enabled?).and_return(false)

      render

      expect(rendered).to render_template('groups/settings/_code_suggestions')
      expect(rendered).not_to have_content('What are code suggestions?')
    end

    it 'renders the settings' do
      allow(view).to receive(:ai_assist_ui_enabled?).and_return(true)

      render

      expect(rendered).to render_template('groups/settings/_code_suggestions')
      field_text = s_('CodeSuggestions|Projects in this group can use Code Suggestions in VS Code')
      expect(rendered).to have_content(field_text)
      beta_link = help_page_path('user/project/repository/code_suggestions')
      expect(rendered).to have_link('What are code suggestions?', href: beta_link)
      test_link = 'https://about.gitlab.com/handbook/legal/testing-agreement/'
      expect(rendered).to have_link('Testing Terms of Use', href: test_link)
    end
  end
end
