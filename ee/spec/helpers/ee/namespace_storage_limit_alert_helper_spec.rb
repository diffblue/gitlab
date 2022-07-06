# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::NamespaceStorageLimitAlertHelper do
  using RSpec::Parameterized::TableSyntax

  let!(:admin) { create(:admin) }

  describe '#purchase_storage_url' do
    subject { helper.purchase_storage_url }

    it { is_expected.to eq(EE::SUBSCRIPTIONS_MORE_STORAGE_URL) }
  end

  describe '#namespace_storage_alert' do
    subject { helper.namespace_storage_alert(namespace) }

    let(:namespace) { build(:namespace) }

    let(:payload) do
      {
        alert_level: :info,
        usage_message: "Usage",
        explanation_message: "Explanation",
        root_namespace: namespace.root_ancestor
      }
    end

    where(additional_repo_storage_by_namespace_enabled: [false, true])

    with_them do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
        allow(namespace).to receive(:additional_repo_storage_by_namespace_enabled?)
          .and_return(additional_repo_storage_by_namespace_enabled)

        allow(helper).to receive(:current_user).and_return(admin)
        allow(admin).to receive(:can?).with(:admin_namespace, namespace.root_ancestor).and_return(true)
        allow_next_instance_of(EE::Namespace::Storage::Notification) do |notification|
          allow(notification).to receive(:payload).and_return(payload)
          allow(notification).to receive(:alert_level).and_return(payload[:alert_level])
        end
      end

      context 'when payload is not empty and no cookie is set' do
        it { is_expected.to eq(payload) }
      end

      context 'when there is no current_user' do
        before do
          allow(helper).to receive(:current_user).and_return(nil)
        end

        it { is_expected.to eq({}) }
      end

      context 'when current_user is not an admin of the namespace' do
        before do
          allow(admin).to receive(:can?).with(:admin_namespace, namespace.root_ancestor).and_return(false)
        end

        it { is_expected.to eq({}) }
      end

      context 'when cookie is set' do
        before do
          helper.request.cookies["hide_storage_limit_alert_#{namespace.id}_info"] = 'true'
        end

        it { is_expected.to eq({}) }
      end
    end
  end

  describe '#namespace_storage_alert_style' do
    subject { helper.namespace_storage_alert_style(alert_level) }

    where(:alert_level, :result) do
      :info      | :info
      :warning   | :warning
      :error     | :danger
      :alert     | :danger
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#namespace_storage_alert_icon' do
    subject { helper.namespace_storage_alert_icon(alert_level) }

    where(:alert_level, :result) do
      :info      | 'information-o'
      :warning   | 'warning'
      :error     | 'error'
      :alert     | 'error'
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#purchase_storage_link_enabled?' do
    subject { helper.purchase_storage_link_enabled?(namespace) }

    let_it_be(:namespace) { build(:namespace) }

    where(:additional_repo_storage_by_namespace_enabled, :result) do
      false | false
      true  | true
    end

    with_them do
      before do
        allow(namespace).to receive(:additional_repo_storage_by_namespace_enabled?)
          .and_return(additional_repo_storage_by_namespace_enabled)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#number_of_hidden_storage_alert_banners' do
    subject { helper.number_of_hidden_storage_alert_banners }

    let_it_be(:namespace) { create(:namespace) }

    context 'when a cookie is set' do
      before do
        helper.request.cookies["hide_storage_limit_alert_#{namespace.id}_info"] = 'true'
      end

      it { is_expected.to eq(1) }
    end

    context 'when two cookies are set' do
      before do
        helper.request.cookies["hide_storage_limit_alert_#{namespace.id}_info"] = 'true'
        helper.request.cookies["hide_storage_limit_alert_#{namespace.id}_danger"] = 'true'
      end

      it { is_expected.to eq(2) }
    end

    context 'when no cookies are set' do
      it { is_expected.to eq(0) }
    end
  end
end
