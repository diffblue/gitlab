# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Groups', feature_category: :continuous_integration do
  include ::Ci::MinutesHelpers

  let_it_be(:group) { create :group }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:project, reload: true) { create(:project, namespace: group) }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  describe 'show a group' do
    context 'with minutes' do
      before do
        project.update!(shared_runners_enabled: true)
        set_ci_minutes_used(group, 300)
        group.update!(shared_runners_minutes_limit: 400)
      end

      context 'when gitlab saas', :saas do
        it 'renders minute report' do
          visit admin_group_path(group)

          expect(page).to have_content('Quota of CI/CD minutes: 300 / 400')
        end

        it 'renders additional minutes' do
          group.update!(extra_shared_runners_minutes_limit: 100)

          visit admin_group_path(group)

          expect(page).to have_content('Additional minutes:')
        end
      end

      context 'when self-managed' do
        it 'renders minute report' do
          visit admin_group_path(group)

          expect(page).not_to have_content('Quota of CI/CD minutes: 300 / 400')
        end

        it 'does not render additional minutes' do
          group.update!(extra_shared_runners_minutes_limit: 100)

          visit admin_group_path(group)

          expect(page).not_to have_content('Additional minutes:')
        end
      end
    end
  end
end
