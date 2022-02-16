# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::NamespacesHelper do
  let!(:user) { create(:user) }
  let!(:user_project_creation_level) { nil }

  let(:user_group) do
    create(:namespace, :with_ci_minutes,
           project_creation_level: user_project_creation_level,
           owner: user,
           ci_minutes_used: ci_minutes_used)
  end

  let(:ci_minutes_used) { 100 }

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
    let(:quota_presenter) { Ci::Minutes::QuotaPresenter.new(quota) }

    describe 'rendering monthly minutes report' do
      let(:report) { quota_presenter.monthly_minutes_report }

      context "when ci minutes quota is not enabled" do
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
      let(:report) { Ci::Minutes::QuotaPresenter.new(quota).purchased_minutes_report }

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

  describe '#buy_additional_minutes_path' do
    subject { helper.buy_additional_minutes_path(namespace) }

    let(:namespace) { build_stubbed(:group) }

    it { is_expected.to eq buy_minutes_subscriptions_path(selected_group: namespace.id) }

    context 'when called for a personal namespace' do
      let(:user) { create(:user) }
      let(:personal_namespace) { build_stubbed(:user_namespace) }

      it 'returns the default purchase' do
        expect(helper.buy_additional_minutes_path(personal_namespace)).to eq EE::SUBSCRIPTIONS_MORE_MINUTES_URL
      end
    end
  end

  describe '#buy_storage_path' do
    subject { helper.buy_storage_path(namespace) }

    let(:namespace) { build_stubbed(:group) }

    it { is_expected.to eq buy_storage_subscriptions_path(selected_group: namespace.id) }

    context 'when called for a personal namespace' do
      let(:user) { create(:user) }
      let(:personal_namespace) { build_stubbed(:user_namespace) }

      it 'returns the default purchase' do
        expect(helper.buy_storage_path(personal_namespace)).to eq EE::SUBSCRIPTIONS_MORE_STORAGE_URL
      end
    end
  end

  describe '#buy_addon_target_attr' do
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
end
