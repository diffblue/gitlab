# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::NamespacesHelper, feature_category: :subgroups do
  using RSpec::Parameterized::TableSyntax
  include NamespacesTestHelper

  let!(:user) { create(:user) }
  let!(:user_project_creation_level) { nil }

  let(:user_group) do
    create(
      :namespace,
      :with_ci_minutes,
      project_creation_level: user_project_creation_level,
      owner: user,
      ci_minutes_used: ci_minutes_used
    )
  end

  let(:ci_minutes_used) { 100 }
  let(:more_storage_url) { ::Gitlab::Routing.url_helpers.subscription_portal_more_storage_url }

  describe '#ci_minutes_report', feature_category: :continuous_integration do
    let(:usage) { Ci::Minutes::Usage.new(user_group) }
    let(:usage_presenter) { Ci::Minutes::UsagePresenter.new(usage) }

    describe 'rendering monthly minutes report' do
      let(:report) { usage_presenter.monthly_minutes_report }

      context "when ci minutes usage is not enabled" do
        before do
          user_group.update!(shared_runners_minutes_limit: 0)
        end

        context 'and the namespace is eligible for unlimited' do
          before do
            allow(user_group).to receive(:root?).and_return(true)
            allow(user_group).to receive(:any_project_with_shared_runners_enabled?).and_return(true)
          end

          it 'returns Unlimited for the limit section' do
            expect(helper.ci_minutes_report(report)).to match(%r{\b100 / Unlimited})
          end
        end

        context 'and the namespace is not eligible for unlimited' do
          before do
            allow(user_group).to receive(:root?).and_return(false)
          end

          it 'returns Not supported for the limit section' do
            expect(helper.ci_minutes_report(report)).to match(%r{\b100 / Not supported})
          end
        end
      end

      context "when it's limited" do
        before do
          allow(user_group).to receive(:any_project_with_shared_runners_enabled?).and_return(true)

          user_group.update!(shared_runners_minutes_limit: 500)
        end

        it 'returns the proper values for used and limit sections' do
          expect(helper.ci_minutes_report(report)).to match(%r{\b100 / 500\b})
        end
      end
    end

    describe 'rendering purchased minutes report' do
      let(:report) { usage_presenter.purchased_minutes_report }

      context 'when extra minutes are assigned' do
        before do
          user_group.update!(extra_shared_runners_minutes_limit: 100)
        end

        context 'when minutes used is higher than monthly minutes limit' do
          let(:ci_minutes_used) { 550 }

          it 'returns the proper values for used and limit sections' do
            expect(helper.ci_minutes_report(report)).to match(%r{\b50 / 100\b})
          end
        end

        context 'when minutes used is lower than monthly minutes limit' do
          let(:ci_minutes_used) { 400 }

          it 'returns the proper values for used and limit sections' do
            expect(helper.ci_minutes_report(report)).to match(%r{\b0 / 100\b})
          end
        end
      end

      context 'when extra minutes are not assigned' do
        it 'returns the proper values for used and limit sections' do
          expect(helper.ci_minutes_report(report)).to match(%r{\b0 / 0\b})
        end
      end
    end
  end

  describe '#buy_additional_minutes_path', feature_category: :consumables_cost_management do
    subject { helper.buy_additional_minutes_path(namespace) }

    let(:namespace) { build_stubbed(:group) }

    it { is_expected.to eq get_buy_minutes_path(namespace) }

    context 'when called for a personal namespace' do
      let(:user) { create(:user) }
      let(:personal_namespace) { build_stubbed(:user_namespace) }

      it 'returns the default purchase' do
        more_minutes_url = ::Gitlab::Routing.url_helpers.subscription_portal_more_minutes_url

        expect(helper.buy_additional_minutes_path(personal_namespace)).to eq more_minutes_url
      end
    end

    context 'when called from a subgroup' do
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }

      it 'returns the selected group id as the parent group' do
        link = helper.buy_additional_minutes_path(subgroup)
        expect(link).to eq get_buy_minutes_path(group)
      end
    end
  end

  describe '#buy_storage_path', feature_category: :consumables_cost_management do
    subject { helper.buy_storage_path(namespace) }

    let(:namespace) { build_stubbed(:group) }

    it { is_expected.to eq get_buy_storage_path(namespace) }

    context 'when called from a subgroup' do
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }

      it 'returns the buy URL with the parent group id' do
        expect(helper.buy_storage_path(subgroup)).to eq get_buy_storage_path(group)
      end
    end

    context 'when called for a personal namespace' do
      let(:user) { create(:user) }
      let(:personal_namespace) { build_stubbed(:user_namespace) }

      it 'returns the default purchase' do
        expect(helper.buy_storage_path(personal_namespace)).to eq more_storage_url
      end
    end
  end

  describe '#buy_storage_url', feature_category: :consumables_cost_management do
    subject { helper.buy_storage_url(namespace) }

    let(:namespace) { build_stubbed(:group) }

    it { is_expected.to eq get_buy_storage_url(namespace) }

    context 'when called from a subgroup' do
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }

      it 'returns the buy URL with the parent group id' do
        expect(helper.buy_storage_url(subgroup)).to eq get_buy_storage_url(group)
      end
    end

    context 'when called for a personal namespace' do
      let(:user) { create(:user) }
      let(:personal_namespace) { build_stubbed(:user_namespace) }

      it 'returns the default purchase' do
        expect(helper.buy_storage_url(personal_namespace)).to eq more_storage_url
      end
    end
  end

  describe '#buy_addon_target_attr', feature_category: :consumables_cost_management do
    subject { helper.buy_addon_target_attr(namespace) }

    let(:namespace) { create(:group) }

    it { is_expected.to eq '_self' }

    context 'when called for a personal namespace' do
      let(:user) { create(:user) }
      let(:personal_namespace) { build_stubbed(:user_namespace) }

      it 'returns _blank' do
        expect(helper.buy_addon_target_attr(personal_namespace)).to eq '_blank'
      end
    end
  end

  describe '#pipeline_usage_app_data', feature_category: :consumables_cost_management do
    let(:minutes_usage) { user_group.ci_minutes_usage }
    let(:minutes_usage_presenter) { ::Ci::Minutes::UsagePresenter.new(minutes_usage) }

    context 'when gitlab sass', :saas do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      shared_examples 'returns a hash with proper SaaS data' do
        it 'matches the returned hash' do
          more_minutes_url = ::Gitlab::Routing.url_helpers.subscription_portal_more_minutes_url

          expect(helper.pipeline_usage_app_data(user_group)).to eql({
            namespace_actual_plan_name: user_group.actual_plan_name,
            namespace_path: user_group.full_path,
            namespace_id: user_group.id,
            user_namespace: user_group.user_namespace?.to_s,
            page_size: Kaminari.config.default_per_page,
            ci_minutes: {
              any_project_enabled: minutes_usage_presenter.any_project_enabled?.to_s,
              last_reset_date: minutes_usage.reset_date,
              display_minutes_available_data: minutes_usage_presenter.display_minutes_available_data?.to_s,
              monthly_minutes_used: minutes_usage_presenter.monthly_minutes_report.used,
              monthly_minutes_used_percentage: minutes_usage_presenter.monthly_percent_used,
              monthly_minutes_limit: minutes_usage_presenter.monthly_minutes_report.limit,
              purchased_minutes_used: minutes_usage_presenter.purchased_minutes_report.used,
              purchased_minutes_used_percentage: minutes_usage_presenter.purchased_percent_used,
              purchased_minutes_limit: minutes_usage_presenter.purchased_minutes_report.limit
            },
            buy_additional_minutes_path: more_minutes_url,
            buy_additional_minutes_target: '_blank'
          })
        end
      end

      it_behaves_like 'returns a hash with proper SaaS data'
    end

    context 'when gitlab self managed' do
      it 'returns a hash without SaaS data' do
        expect(helper.pipeline_usage_app_data(user_group)).to eql({
          namespace_actual_plan_name: user_group.actual_plan_name,
          namespace_path: user_group.full_path,
          namespace_id: user_group.id,
          user_namespace: user_group.user_namespace?.to_s,
          page_size: Kaminari.config.default_per_page,
          ci_minutes: {
            any_project_enabled: minutes_usage_presenter.any_project_enabled?.to_s,
            last_reset_date: minutes_usage.reset_date,
            display_minutes_available_data: minutes_usage_presenter.display_minutes_available_data?.to_s,
            monthly_minutes_used: minutes_usage_presenter.monthly_minutes_report.used,
            monthly_minutes_used_percentage: minutes_usage_presenter.monthly_percent_used,
            monthly_minutes_limit: minutes_usage_presenter.monthly_minutes_report.limit
          }
        })
      end
    end
  end

  describe '#purchase_storage_url', feature_category: :consumables_cost_management do
    subject { helper.purchase_storage_url }

    it { is_expected.to eq(more_storage_url) }
  end

  describe '#storage_usage_app_data', feature_category: :consumables_cost_management do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:admin) { create(:user, namespace: namespace) }

    before do
      allow(helper).to receive(:current_user).and_return(admin)
      stub_ee_application_setting(should_check_namespace_plan: true)
    end

    it 'returns a hash with storage data' do
      expect(helper.storage_usage_app_data(namespace)).to eql({
        namespace_id: namespace.id,
        namespace_path: namespace.full_path,
        user_namespace: namespace.user_namespace?.to_s,
        default_per_page: Kaminari.config.default_per_page,
        purchase_storage_url: more_storage_url,
        buy_addon_target_attr: '_blank',
        storage_limit_enforced: 'false',
        can_show_inline_alert: 'false'
      })
    end
  end
end
