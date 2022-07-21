# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project settings > Issues', :js do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  context 'when Issues are initially enabled' do
    context 'when Pipelines are initially enabled' do
      before do
        visit edit_project_path(project)
      end

      it 'shows the Issues settings' do
        expect(page).to have_content('Configure default branch name for branches created from issues.')

        value = "feature-%{id}"

        within('section.rspec-issues-settings') do
          fill_in 'project[issue_branch_template]', with: value

          click_on('Save changes')
        end

        expect(project.reload.issue_branch_template).to eq(value)
      end
    end
  end
end
