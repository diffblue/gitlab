# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::Storage::ProjectPreEnforcementAlertComponent, :saas, type: :component do
  let_it_be_with_refind(:group) { create(:group, :with_root_storage_statistics) }
  let_it_be_with_refind(:project) { create(:project, group: group) }
  let_it_be_with_refind(:user) { create(:user) }

  subject(:component) { described_class.new(context: project, user: user) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)
  end

  context 'when project' do
    before do
      group.root_storage_statistics.update!(
        storage_size: ::EE::Gitlab::Namespaces::Storage::Enforcement::FREE_NAMESPACE_STORAGE_CAP
      )
      project.add_maintainer(user)
    end

    it 'includes the correct project info in the banner text' do
      render_inline(component)

      expect(page).to have_text "The #{project.name} project will be affected by this."
    end
  end
end
