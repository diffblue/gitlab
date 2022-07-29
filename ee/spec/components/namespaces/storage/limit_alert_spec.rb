# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::Storage::LimitAlert, :saas, type: :component do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be_with_refind(:user) { create(:user) }

  # EE::Namespace::Storage::Notification #payload
  let(:notification_payload) do
    {
      explanation_message: 'explanation message',
      usage_message: 'usage message',
      alert_level: :info,
      root_namespace: group.root_ancestor
    }
  end

  subject(:component) { described_class.new(context: group, user: user, notification_data: notification_payload) }

  before do
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_ee_application_setting(enforce_namespace_storage_limit: true)
    stub_ee_application_setting(automatic_purchased_storage_allocation: true)
    stub_feature_flags(namespace_storage_limit: false)
  end

  it 'renders the alert title' do
    render_inline(component)
    expect(page).to have_content(notification_payload[:usage_message])
  end

  it 'renders the alert message' do
    render_inline(component)
    expect(page).to have_content(notification_payload[:explanation_message])
  end

  describe 'purchase more storage link' do
    it 'does not render link if user is not an owner of root group' do
      render_inline(component)
      expect(page).not_to have_link(
        'Purchase more storage',
        href: buy_storage_subscriptions_path(selected_group: group.root_ancestor.id)
      )
    end

    it 'renders link if user is an owner of root group' do
      allow(Ability).to receive(:allowed?).with(user, :owner_access, group.root_ancestor).and_return(true)

      render_inline(component)
      expect(page).to have_link(
        'Purchase more storage',
        href: buy_storage_subscriptions_path(selected_group: group.root_ancestor.id)
      )
    end
  end

  it 'renders Usage Quotas link' do
    render_inline(component)
    expect(page).to have_link(
      'View usage details',
      href: usage_quotas_path(group.root_ancestor, anchor: 'storage-quota-tab')
    )
  end

  describe 'alert callout data' do
    where(:alert_level, :user_namespace) do
      :info      | true
      :warning   | false
      :error     | true
      :alert     | false
    end

    with_them do
      let(:notification_payload) do
        {
          explanation_message: 'explanation message',
          usage_message: 'usage message',
          alert_level: alert_level,
          root_namespace: group.root_ancestor
        }
      end

      before do
        allow(group.root_ancestor).to receive(:user_namespace?).and_return(user_namespace)
      end

      it 'renders the correct callout data' do
        render_inline(component)

        dismiss_endpoint_path = user_namespace ? callouts_path : group_callouts_path

        expect(page).to have_css("[data-feature-id='namespace_storage_limit_banner_#{alert_level}_threshold']")
        expect(page).to have_css("[data-dismiss-endpoint='#{dismiss_endpoint_path}']")
        expect(page).to have_css("[data-group-id='#{group.root_ancestor.id}']")
      end
    end
  end

  describe 'icon and alert variant' do
    where(:alert_level, :variant, :icon) do
      :info      | 'info'    | 'information-o'
      :warning   | 'warning' | 'warning'
      :error     | 'danger'  | 'error'
      :alert     | 'danger'  | 'error'
    end

    with_them do
      let(:notification_payload) do
        {
          explanation_message: 'explanation message',
          usage_message: 'usage message',
          alert_level: alert_level,
          root_namespace: group.root_ancestor
        }
      end

      it 'renders the correct icon and variant' do
        render_inline(component)

        expect(page).to have_css("[data-testid='#{icon}-icon']")
        expect(page).to have_css(".gl-alert-#{variant}")
      end
    end
  end

  context 'when user has dismissed banner' do
    before do
      create(
        :group_callout,
        user: user,
        group: group,
        feature_name: 'namespace_storage_limit_banner_info_threshold'
      )
    end

    it 'does not render' do
      render_inline(component)
      expect(page).not_to have_css('.js-namespace-storage-alert')
    end
  end
end
