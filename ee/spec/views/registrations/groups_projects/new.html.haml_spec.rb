# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/groups_projects/new' do
  let(:google_tag_manager_id) { 'GTM-WWKMTWS' }

  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project) }

  before do
    assign(:group, group)
    assign(:project, project)
    stub_config(extra:
                  {
                    google_tag_manager_id: google_tag_manager_id,
                    google_tag_manager_nonce_id: google_tag_manager_id
                  })
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:import_sources_enabled?).and_return(false)
  end

  context 'when Google Tag Manager is enabled' do
    before do
      allow(view).to receive(:google_tag_manager_enabled?).and_return(true)
      render
    end

    subject { rendered }

    it 'contains a Google Tag Manager tag' do
      is_expected.to match(/www.googletagmanager.com/)
    end
  end

  context 'when Google Tag Manager is disabled' do
    before do
      allow(view).to receive(:google_tag_manager_enabled?).and_return(false)
      render
    end

    subject { rendered }

    it 'does not contain a Google Tag Manager tag' do
      is_expected.not_to match(/www.googletagmanager.com/)
    end
  end

  context 'with expected DOM elements' do
    it 'contains js-groups-projects-form class' do
      render

      expect(rendered).to have_css('.js-groups-projects-form')
    end

    context 'with require_verification_for_namespace_creation experiment' do
      context 'with control experience' do
        before do
          stub_experiments(require_verification_for_namespace_creation: :control)
        end

        it 'does not have credit card verification items' do
          render

          expect(rendered).not_to have_css('.js-credit-card-verification')
          expect(rendered).not_to have_css('.js-exit-registration-verification')
        end

        it 'has project creation form tabs' do
          render

          expect(rendered).to have_css('.js-toggle-container')
          expect(rendered).to have_css('#blank-project-pane')
          expect(rendered).to have_css('#import-project-pane')
        end
      end

      context 'with candidate experience' do
        before do
          stub_experiments(require_verification_for_namespace_creation: :candidate)
        end

        context 'with an exit to registration verification' do
          before do
            user.update!(requires_credit_card_verification: true)
          end

          it 'has expected selectors' do
            render

            expect(rendered).to have_css('.js-credit-card-verification')
            expect(rendered).to have_css('.js-exit-registration-verification')
          end
        end

        context 'without an exit to the registration verification' do
          it 'has expected selectors' do
            render

            expect(rendered).to have_css('.js-credit-card-verification')
            expect(rendered).not_to have_css('.js-exit-registration-verification')
          end

          context 'when exit_registration_verification is disabled' do
            before do
              user.update!(requires_credit_card_verification: true)
              stub_feature_flags(exit_registration_verification: false)
            end

            it 'has expected selectors' do
              render

              expect(rendered).to have_css('.js-credit-card-verification')
              expect(rendered).not_to have_css('.js-exit-registration-verification')
            end
          end
        end
      end
    end
  end
end
