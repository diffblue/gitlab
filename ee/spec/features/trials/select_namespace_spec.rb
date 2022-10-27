# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial Select Namespace', :js, feature_category: :purchase do
  include ListboxInputHelper

  let_it_be(:group) { create(:group, path: 'group-test') }
  let_it_be(:new_group_name) { 'GitLab' }
  let_it_be(:user) { create(:user) }

  before do
    group.add_owner(user)
    allow(Gitlab).to receive(:com?).and_return(true).at_least(:once)
    sign_in(user)
  end

  context 'when user' do
    let(:url_params) { {} }

    before do
      visit select_trials_path(url_params)
      wait_for_all_requests

      choose :trial_entity_company if url_params[:glm_source] != 'about.gitlab.com'
    end

    context 'when source is not about.gitlab.com' do
      it 'shows company/individual question' do
        expect(page).to have_content('Who will be using GitLab?')
      end
    end

    context 'when source is about.gitlab.com' do
      let(:url_params) { { glm_source: 'about.gitlab.com' } }

      it 'hides company/individual duplicate question' do
        expect(page).not_to have_content('Who will be using GitLab?')
      end
    end

    context 'selects create a new group' do
      before do
        listbox_input "Create group", from: '[data-testid="namespace-selector"]'
      end

      it 'shows the new group name input' do
        expect(page).to have_selector('fieldset', text: 'New Group Name')
        expect(page).to have_content('Who will be using GitLab?')
      end

      context 'enters a valid new group name' do
        context 'when user can create groups' do
          it 'proceeds to the next step' do
            service = instance_double(GitlabSubscriptions::Trials::ApplyTrialService, execute: ServiceResponse.success)
            expect(GitlabSubscriptions::Trials::ApplyTrialService).to receive(:new).and_return(service)

            fill_in 'new_group_name', with: new_group_name

            click_button 'Start your free trial'

            wait_for_requests

            expect(page).not_to have_css('flash-container')
            expect(page).to have_current_path('/gitlab', ignore_query: true)
          end
        end

        context 'when user can not create groups' do
          before do
            user.update_attribute(:can_create_group, false)
          end

          it 'returns 404' do
            fill_in 'new_group_name', with: new_group_name

            click_button 'Start your free trial'

            expect(page).to have_content('Page Not Found')
          end
        end
      end

      context 'enters an existing group name' do
        let!(:namespace) { create(:namespace, owner_id: user.id, path: 'gitlab') }

        it 'proceeds to the next step with a unique url' do
          service = instance_double(GitlabSubscriptions::Trials::ApplyTrialService, execute: ServiceResponse.success)
          expect(GitlabSubscriptions::Trials::ApplyTrialService).to receive(:new).and_return(service)

          fill_in 'new_group_name', with: namespace.path

          click_button 'Start your free trial'

          wait_for_requests

          expect(page).not_to have_css('flash-container')
          expect(page).to have_current_path('/gitlab1', ignore_query: true)
        end
      end

      context 'and does not enter a new group name' do
        it 'shows validation error' do
          click_button 'Start your free trial'

          message = page.find_field('new_group_name').native.attribute('validationMessage')

          expect(message).to eq('Please fill out this field.')
          expect(page).to have_current_path(select_trials_path, ignore_query: true)
        end
      end
    end

    context 'selects an existing group' do
      before do
        listbox_input group.name, from: '[data-testid="namespace-selector"]'
      end

      context 'without trial plan' do
        it 'does not show the new group name input' do
          expect(page).not_to have_field('new_group_name')
          expect(page).to have_content('Who will be using GitLab?')
        end

        it 'applies trial and redirects to dashboard' do
          service = instance_double(GitlabSubscriptions::Trials::ApplyTrialService, execute: ServiceResponse.success)
          expect(GitlabSubscriptions::Trials::ApplyTrialService).to receive(:new).and_return(service)

          click_button 'Start your free trial'

          wait_for_requests

          expect(page).to have_current_path("/#{group.path}", ignore_query: true)
        end
      end

      context 'with trial plan' do
        let!(:error_message) { 'Validation failed: Gl namespace can have only one trial' }

        it 'shows validation error' do
          service = instance_double(GitlabSubscriptions::Trials::ApplyTrialService,
                                    execute: ServiceResponse.error(message: error_message))
          expect(GitlabSubscriptions::Trials::ApplyTrialService).to receive(:new).and_return(service)

          click_button 'Start your free trial'

          expect(find('[data-testid="alert-danger"]')).to have_text(error_message)
          expect(page).to have_current_path(apply_trials_path, ignore_query: true)
          expect(find_field('namespace_id', type: :hidden).value).to eq(group.id.to_s)

          # new group name should be functional
          listbox_input 'Create group', from: '[data-testid="namespace-selector"]'

          expect(page).to have_field('new_group_name')
          expect(find('#trial_entity_individual').checked?).to be(false)
          expect(find('#trial_entity_company').checked?).to be(true)
        end
      end
    end
  end
end
