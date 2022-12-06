# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project security discover page', :js, :saas, feature_category: :projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { user.namespace }

  before do
    sign_in(user)
    visit(project_security_discover_path(project))
  end

  context 'when project is a personal project (has no group)' do
    let_it_be(:project) { create(:project, namespace: namespace, name: 'Project No Group') }

    shared_examples 'move personal project modal content' do
      it 'loads the modal with correct content' do
        page.click_button(button_text)

        expect(page).to have_content "Your project #{project.name} is not in a group"
        expect(page).to have_content "#{project.name} is a personal project, so none of this is available."
        expect(page).to have_link('Learn to move a project to a group',
                                  href: help_page_path('tutorials/move_personal_project_to_a_group'))
      end
    end

    context 'when Upgrade now is clicked' do
      let_it_be(:button_text) { 'Upgrade now' }

      it_behaves_like 'move personal project modal content'
    end

    context 'when Start a free trial is clicked' do
      let_it_be(:button_text) { 'Start a free trial' }

      it_behaves_like 'move personal project modal content'
    end
  end
end
