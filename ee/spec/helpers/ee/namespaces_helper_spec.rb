# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::NamespacesHelper do
  let!(:admin) { create(:admin) }
  let!(:admin_project_creation_level) { nil }
  let!(:admin_group) do
    create(:group,
           :private,
           project_creation_level: admin_project_creation_level)
  end

  let!(:user) { create(:user) }
  let!(:user_project_creation_level) { nil }
  let!(:user_group) do
    create(:group,
           :private,
           project_creation_level: user_project_creation_level)
  end

  before do
    admin_group.add_owner(admin)
    user_group.add_owner(user)
  end

  describe '#ci_minutes_progress_bar' do
    it 'shows a green bar if percent is 0' do
      expect(helper.ci_minutes_progress_bar(0)).to match(/success.*0%/)
    end

    it 'shows a green bar if percent is lower than 70' do
      expect(helper.ci_minutes_progress_bar(69)).to match(/success.*69%/)
    end

    it 'shows a yellow bar if percent is 70' do
      expect(helper.ci_minutes_progress_bar(70)).to match(/warning.*70%/)
    end

    it 'shows a yellow bar if percent is higher than 70 and lower than 95' do
      expect(helper.ci_minutes_progress_bar(94)).to match(/warning.*94%/)
    end

    it 'shows a red bar if percent is 95' do
      expect(helper.ci_minutes_progress_bar(95)).to match(/danger.*95%/)
    end

    it 'shows a red bar if percent is higher than 100 and caps the value to 100' do
      expect(helper.ci_minutes_progress_bar(120)).to match(/danger.*100%/)
    end
  end

  describe '#ci_minutes_report' do
    let(:quota) { Ci::Minutes::Quota.new(user_group) }

    describe 'rendering monthly minutes report' do
      let(:report) { quota.monthly_minutes_report }

      context "when ci minutes quota is not enabled" do
        before do
          allow(user_group).to receive(:shared_runners_minutes_limit_enabled?).and_return(false)
        end

        context 'and the namespace is eligible for unlimited' do
          before do
            allow(quota).to receive(:namespace_eligible?).and_return(true)
            allow(user_group).to receive(:any_project_with_shared_runners_enabled?).and_return(true)
          end

          it 'returns Unlimited for the limit section' do
            expect(helper.ci_minutes_report(report)).to match(%r{0 / Unlimited})
          end

          it 'returns the proper value for the used section' do
            allow(user_group).to receive(:shared_runners_seconds).and_return(100 * 60)

            expect(helper.ci_minutes_report(report)).to match(%r{100 / Unlimited})
          end
        end

        context 'and the namespace is not eligible for unlimited' do
          before do
            allow(quota).to receive(:namespace_eligible?).and_return(false)
          end

          it 'returns Not supported for the limit section' do
            expect(helper.ci_minutes_report(report)).to match(%r{0 / Not supported})
          end
        end
      end

      context "when it's limited" do
        before do
          allow(user_group).to receive(:any_project_with_shared_runners_enabled?).and_return(true)
          allow(user_group).to receive(:shared_runners_seconds).and_return(100 * 60)

          user_group.update!(shared_runners_minutes_limit: 500)
        end

        it 'returns the proper values for used and limit sections' do
          expect(helper.ci_minutes_report(report)).to match(%r{100 / 500})
        end
      end
    end

    describe 'rendering purchased minutes report' do
      let(:report) { quota.purchased_minutes_report }

      context 'when extra minutes are assigned' do
        it 'returns the proper values for used and limit sections' do
          allow(user_group).to receive(:shared_runners_seconds).and_return(50 * 60)
          user_group.update!(extra_shared_runners_minutes_limit: 100)

          expect(helper.ci_minutes_report(report)).to match(%r{50 / 100})
        end
      end

      context 'when extra minutes are not assigned' do
        it 'returns the proper values for used and limit sections' do
          expect(helper.ci_minutes_report(report)).to match(%r{0 / 0})
        end
      end
    end
  end

  describe '#temporary_storage_increase_visible?' do
    subject { helper.temporary_storage_increase_visible?(namespace) }

    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:admin) { create(:user, namespace: namespace) }
    let_it_be(:user) { create(:user) }

    context 'when enforce_namespace_storage_limit setting enabled' do
      before do
        stub_application_setting(enforce_namespace_storage_limit: true)
      end

      context 'when current_user is admin of namespace' do
        before do
          allow(helper).to receive(:current_user).and_return(admin)
        end

        it { is_expected.to eq(true) }

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(temporary_storage_increase: false)
          end

          it { is_expected.to eq(false) }
        end
      end

      context 'when current_user is not the admin of namespace' do
        before do
          allow(helper).to receive(:current_user).and_return(user)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when enforce_namespace_storage_limit setting disabled' do
      before do
        stub_application_setting(enforce_namespace_storage_limit: false)
      end

      context 'when current_user is admin of namespace' do
        before do
          allow(helper).to receive(:current_user).and_return(admin)
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#link_to_buy_additional_minutes_path' do
    subject { helper.link_to_buy_additional_minutes_path(namespace) }

    let_it_be(:namespace) { create(:group) }

    context 'new_route_ci_minutes_purchase' do
      context 'when is disabled' do
        before do
          stub_feature_flags(new_route_ci_minutes_purchase: false)
        end

        it { is_expected.to be EE::SUBSCRIPTIONS_MORE_MINUTES_URL }
      end

      context 'when is enabled' do
        it { is_expected.to eq buy_minutes_subscriptions_path(selected_group: namespace.id) }
      end

      context 'when is enabled only for a specific namespace' do
        let_it_be(:enabled_namespace) { create(:group) }
        let_it_be(:disabled_namespace) { create(:group) }

        before do
          stub_feature_flags(new_route_ci_minutes_purchase: false)
          stub_feature_flags(new_route_ci_minutes_purchase: enabled_namespace)
        end

        it 'returns the default purchase path for the disabled namespace' do
          expect(helper.link_to_buy_additional_minutes_path(disabled_namespace)).to be EE::SUBSCRIPTIONS_MORE_MINUTES_URL
        end

        it 'returns GitLab purchase path for the disabled namespace' do
          expect(helper.link_to_buy_additional_minutes_path(enabled_namespace)).to eq buy_minutes_subscriptions_path(selected_group: enabled_namespace.id)
        end
      end

      context 'when called for a personal namespace' do
        let_it_be(:user) { create(:user) }
        let_it_be(:personal_namespace) { user.namespace }

        it 'returns the default purchase' do
          expect(helper.link_to_buy_additional_minutes_path(personal_namespace)).to be EE::SUBSCRIPTIONS_MORE_MINUTES_URL
        end
      end
    end
  end
end
