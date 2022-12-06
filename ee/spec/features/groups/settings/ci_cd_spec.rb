# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group CI/CD settings', feature_category: :continuous_integration do
  include Spec::Support::Helpers::ModalHelpers
  include WaitForRequests

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before_all do
    group.add_owner(user)
  end

  before do
    sign_in(user)
  end

  describe 'Runners section', :js do
    shared_examples 'does not show stale runners cleanup' do
      it 'does not show toggle' do
        expect(page).not_to have_content(s_('Runners|Enable stale runner cleanup'))
      end
    end

    shared_examples 'clicks on toggle to enable stale runners cleanup' do
      it 'clicks on toggle to enable setting', :js do
        modal_ok_msg = s_('Runners|Yes, start deleting stale runners')

        page.find('[data-testid="stale-runner-cleanup-toggle"] button').click

        wait_for(page.find_button(modal_ok_msg)) do
          click_button(modal_ok_msg)
          wait_for_requests

          expect(page).to have_selector('[data-testid="stale-runner-cleanup-toggle"] button.is-checked')
          expect(group.reload.ci_cd_settings.allow_stale_runner_pruning?).to be(true)
        end
      end
    end

    before do
      group.ci_cd_settings.update!(allow_stale_runner_pruning: false)
    end

    context 'when stale_runner_cleanup_for_namespace licensed feature is available' do
      before do
        stub_licensed_features(stale_runner_cleanup_for_namespace: true)

        visit group_settings_ci_cd_path(group)
        wait_for_requests
      end

      it_behaves_like 'clicks on toggle to enable stale runners cleanup'
    end

    context 'when stale_runner_cleanup_for_namespace licensed feature is not available' do
      before do
        stub_licensed_features(stale_runner_cleanup_for_namespace: false)

        visit group_settings_ci_cd_path(group)
        wait_for_requests
      end

      it_behaves_like 'does not show stale runners cleanup'
    end
  end
end
