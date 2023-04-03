# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::Storage::ProjectPreEnforcementAlertComponent, :saas, type: :component do
  let_it_be_with_refind(:group) { create(:group, :with_root_storage_statistics) }
  let_it_be_with_refind(:user) { create(:user) }

  subject(:component) { described_class.new(context: project, user: user) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)

    project.add_maintainer(user)
    create(:plan_limits, plan: group.root_ancestor.actual_plan, notification_limit: 500)
  end

  context 'with project in a group' do
    let_it_be_with_refind(:project) { create(:project, group: group) }

    before do
      group.root_storage_statistics.update!(
        storage_size: 5.gigabytes
      )
    end

    it 'includes the correct project info in the banner text' do
      render_inline(component)

      expect(page).to have_text "The #{project.name} project will be affected by this."

      expect(page).to have_css("[data-dismiss-endpoint='#{group_callouts_path}']")
      expect(page).to have_css("[data-group-id='#{group.root_ancestor.id}']")
    end
  end

  context 'with project belonging to user' do
    let_it_be_with_refind(:project) { create(:project) }

    before do
      storage = instance_double(
        Namespace::RootStorageStatistics,
        storage_size: 5.gigabytes
      )

      allow(project.root_ancestor)
        .to receive(:root_storage_statistics)
        .and_return(storage)
    end

    it 'includes the correct project info in the banner text' do
      render_inline(component)

      expect(page).to have_text "The #{project.name} project will be affected by this."

      expect(page).to have_css("[data-dismiss-endpoint='#{project_callouts_path}']")
      expect(page).to have_css("[data-project-id='#{project.id}']")
    end
  end
end
