# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::Preview, :saas do
  let_it_be(:namespace, reload: true) { create(:group_with_plan, :private, plan: :free_plan) }
  let(:free_user_count) { 1 }

  before do
    stub_ee_application_setting(dashboard_limit_enabled: true)
    allow(namespace).to receive(:free_plan_members_count).and_return(free_user_count)
    stub_ee_application_setting(dashboard_enforcement_limit: 3)
  end

  describe '#over_limit?' do
    subject(:over_limit?) { described_class.new(namespace).over_limit? }

    context 'when :preview_free_user_cap is disabled' do
      before do
        stub_feature_flags(preview_free_user_cap: false)
      end

      it { is_expected.to be false }
    end

    context 'when :preview_free_user_cap is enabled' do
      it { is_expected.to be true }

      context 'when the namespace is public' do
        before do
          namespace.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it { is_expected.to be false }
      end

      context 'with a net new namespace' do
        let(:enforcement_date) { Date.today }
        let_it_be(:namespace) do
          travel_to(Date.today + 2.days) do
            create(:group_with_plan, :private, plan: :free_plan)
          end
        end

        before do
          stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          stub_ee_application_setting(dashboard_notification_limit: 1)
          stub_ee_application_setting(dashboard_limit: 3)
        end

        context 'when under the dashboard_limit preview is honored' do
          let(:free_user_count) { 2 }

          it { is_expected.to be true }
        end

        context 'when at dashboard_limit preview is honored' do
          let(:free_user_count) { 3 }

          it { is_expected.to be true }
        end

        context 'when over the dashboard_limit preview is off' do
          let(:free_user_count) { 4 }

          it { is_expected.to be false }
        end
      end

      context 'with an existing namespace' do
        before do
          stub_ee_application_setting(dashboard_notification_limit: 1)
        end

        context 'when under the dashboard_enforcement_limit preview is honored' do
          let(:free_user_count) { 2 }

          it { is_expected.to be true }
        end

        context 'when at dashboard_enforcement_limit preview is honored' do
          let(:free_user_count) { 3 }

          it { is_expected.to be true }
        end

        context 'when over the dashboard_enforcement_limit preview is off' do
          let(:free_user_count) { 4 }

          it { is_expected.to be false }
        end
      end
    end
  end
end
