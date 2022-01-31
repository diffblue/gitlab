# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New Group page' do
  describe 'toggling the invite members section', :js do
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
      visit new_group_path
      click_link 'Create group'
    end

    describe 'when selecting options from the "Who will be using this group?" question' do
      it 'toggles the invite members section' do
        expect(page).to have_content('Invite Members')
        choose 'Just me'
        expect(page).not_to have_content('Invite Members')
        choose 'My company or team'
        expect(page).to have_content('Invite Members')
      end
    end
  end

  describe 'identity verification experiment', :js do
    let(:variant) { :control }
    let(:query_params) { {} }

    let_it_be(:user_created_at) { RequireVerificationForNamespaceCreationExperiment::EXPERIMENT_START_DATE + 1.hour }
    let_it_be(:user) { create(:user, created_at: user_created_at) }

    subject(:visit_new_group_page) do
      sign_in(user)
      visit new_group_path(query_params)
    end

    before do
      stub_experiments(require_verification_for_namespace_creation: variant)
    end

    context 'when creating a top-level group' do
      before do
        visit_new_group_page
      end

      it 'does not show verification form' do
        expect(page).not_to have_content('Verify your identity')
        expect(page).not_to have_content('Before you create your group')
        expect(page).to have_content('Create new group')
      end

      context 'when in candidate path' do
        let(:variant) { :candidate }

        it 'shows verification form' do
          expect(page).to have_content('Verify your identity')
          expect(page).to have_content('Before you create your group')
          expect(page).not_to have_content('Create new group')
        end
      end
    end

    context 'when creating a sub-group' do
      let(:parent_group) { create(:group) }
      let(:query_params) { { parent_id: parent_group.id } }
      let(:variant) { :candidate }

      before do
        parent_group.add_owner(user)
        visit_new_group_page
      end

      it 'does not show verification form' do
        expect(page).not_to have_content('Verify your identity')
        expect(page).not_to have_content('Before you create your group')
        expect(page).to have_content('Create new group')
      end
    end
  end
end
