# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::Storage::SubgroupPreEnforcementAlertComponent, :saas, type: :component do
  let_it_be_with_refind(:group) { create(:group, :with_root_storage_statistics) }
  let_it_be_with_refind(:subgroup) { create(:group, parent: group) }
  let_it_be_with_refind(:user) { create(:user) }

  subject(:component) { described_class.new(context: subgroup, user: user) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)
  end

  context 'when subgroup' do
    before do
      group.root_storage_statistics.update!(
        storage_size: 5.gigabytes
      )
      subgroup.add_guest(user)
      create(:plan_limits, plan: group.root_ancestor.actual_plan, notification_limit: 500)
    end

    it 'includes the correct subgroup info in the banner text' do
      render_inline(component)

      expect(page).to have_text "The #{subgroup.name} group will be affected by this."
    end
  end
end
