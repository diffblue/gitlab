# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::Storage::UserNamespacePreEnforcementAlertComponent, :saas, type: :component do
  let(:storage_enforcement_date) { Date.today + 31 }

  let_it_be_with_refind(:user) { create(:user) }

  subject(:component) { described_class.new(context: user.namespace, user: user) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)
  end

  context 'when user namespace' do
    before do
      allow(user.namespace).to receive(:user_namespace?).and_return(true)
      allow(user.namespace).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)

      create(
        :namespace_root_storage_statistics,
        namespace: user.namespace,
        storage_size: ::EE::Gitlab::Namespaces::Storage::Enforcement::FREE_NAMESPACE_STORAGE_CAP
      )
    end

    it 'includes the storage_enforcement_date in the banner text' do
      render_inline(component)

      expect(page).to have_text "Effective #{storage_enforcement_date}, namespace storage limits will apply"
    end

    it 'includes the correct navigation instruction in the banner text' do
      render_inline(component)

      expect(page).to have_text "View and manage your usage from User settings > Usage quotas"
    end
  end
end
