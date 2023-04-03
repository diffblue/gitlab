# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Repository size limit banner", :js, :saas, feature_category: :consumables_cost_management do
  let_it_be(:owner) { create(:user) }
  let_it_be(:free_group) { create(:group) }
  let_it_be_with_refind(:free_group_project) { create(:project, :repository, group: free_group) }
  let_it_be(:paid_group) { create(:group_with_plan, plan: :ultimate_plan) }
  let_it_be_with_refind(:paid_group_project) { create(:project, :repository, group: paid_group) }

  before_all do
    free_group.add_owner(owner)
    paid_group.add_owner(owner)
  end

  before do
    sign_in(owner)
    stub_ee_application_setting(automatic_purchased_storage_allocation: true)
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(repository_size_limit: 10.megabytes)
  end

  context 'when namespace storage limits are disabled' do
    before do
      stub_ee_application_setting(enforce_namespace_storage_limit: false)
      stub_feature_flags(
        namespace_storage_limit: false,
        enforce_storage_limit_for_paid: false,
        enforce_storage_limit_for_free: false
      )
    end

    it 'shows the banner when a project repository in a free group has exceed the storage limit' do
      free_group_project.statistics.update!(repository_size: 11.megabytes)

      visit(group_path(free_group))

      expect(page).to have_text("You have reached the free storage limit of 10 MB on one or more projects")
    end

    it 'shows the banner when a project repository in a paid group has exceed the storage limit' do
      paid_group_project.statistics.update!(repository_size: 11.megabytes)

      visit(group_path(paid_group))

      expect(page).to have_text("You have reached the free storage limit of 10 MB on one or more projects")
    end
  end

  context 'when namespace storage limits are enabled for free plans' do
    before do
      stub_ee_application_setting(enforce_namespace_storage_limit: true)
      stub_feature_flags(
        namespace_storage_limit: true,
        enforce_storage_limit_for_paid: false,
        enforce_storage_limit_for_free: true
      )
    end

    it 'shows the banner when a project repository in a paid group has exceed the storage limit' do
      paid_group_project.statistics.update!(repository_size: 11.megabytes)

      visit(group_path(paid_group))

      expect(page).to have_text("You have reached the free storage limit of 10 MB on one or more projects")
    end
  end
end
