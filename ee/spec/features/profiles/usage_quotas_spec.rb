# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Usage Quota' do
  include ::Ci::MinutesHelpers

  using RSpec::Parameterized::TableSyntax

  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:namespace, reload: true) { user.namespace }
  let_it_be(:statistics, reload: true) { create(:namespace_statistics, namespace: namespace) }
  let_it_be(:project, reload: true) { create(:project, namespace: namespace) }
  let_it_be(:other_project) { create(:project, namespace: namespace, shared_runners_enabled: false) }

  before do
    gitlab_sign_in(user)
  end

  it 'is linked within the profile page' do
    visit profile_path

    page.within('.nav-sidebar') do
      expect(page).to have_selector(:link_or_button, 'Usage Quotas')
    end
  end

  describe 'shared runners use' do
    where(:shared_runners_enabled, :used, :quota, :usage_class, :usage_text) do
      false | 300  | 500 | 'success' | '300 / Not supported minutes 0% used'
      true  | 300  | nil | 'success' | '300 / Unlimited minutes Unlimited'
      true  | 300  | 500 | 'success' | '300 / 500 minutes 60% used'
      true  | 1000 | 500 | 'danger'  | '1000 / 500 minutes 200% used'
    end

    with_them do
      let(:no_shared_runners_text) { 'Shared runners are disabled, so there are no limits set on pipeline usage' }

      before do
        project.update!(shared_runners_enabled: shared_runners_enabled)
        set_ci_minutes_used(namespace, used)
        namespace.update!(shared_runners_minutes_limit: quota)

        visit profile_usage_quotas_path
      end

      it 'shows the correct quota status' do
        page.within('.pipeline-quota') do
          expect(page).to have_content(usage_text)
          expect(page).to have_selector(".bg-#{usage_class}")
        end
      end

      it 'shows the correct per-project metrics' do
        page.within('.pipeline-project-metrics') do
          expect(page).not_to have_content(other_project.name)

          if shared_runners_enabled
            expect(page).to have_content(project.name)
            expect(page).not_to have_content(no_shared_runners_text)
          else
            expect(page).not_to have_content(project.name)
            expect(page).to have_content(no_shared_runners_text)
          end
        end
      end
    end
  end
end
