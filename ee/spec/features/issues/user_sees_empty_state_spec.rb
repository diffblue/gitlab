# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issues', :js, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:auditor) { create(:user, auditor: true) }

  shared_examples 'empty state' do |expect_button|
    it "shows empty state #{expect_button ? 'with' : 'without'} \"New issue\" button" do
      visit project_issues_path(project)

      expect(page).to have_content('Use issues to collaborate on ideas, solve problems, and plan work')
      expect(page).to have_content('Learn more about issues.')
      expect(page.has_link?('New issue')).to be(expect_button)
    end
  end

  context 'when signed in user is an Auditor' do
    before do
      sign_in(auditor)
    end

    context 'when user is not a member of the project' do
      it_behaves_like 'empty state', false
    end

    context 'when user is a member of the project' do
      before do
        project.add_guest(auditor)
      end

      it_behaves_like 'empty state', true
    end
  end
end
