# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersHelper, feature_category: :user_profile do
  let(:user) { build_stubbed(:user) }

  describe '#trials_allowed?' do
    context 'without cache concerns' do
      using RSpec::Parameterized::TableSyntax

      where(
        has_paid_namespace?: [true, false],
        user?: [true, false],
        check_namespace_plan?: [true, false],
        group_without_trial?: [true, false]
      )

      with_them do
        let(:local_user) { user? ? user : nil }

        before do
          stub_ee_application_setting(should_check_namespace_plan: check_namespace_plan?)
          allow(user).to receive(:owns_group_without_trial?) { group_without_trial? }
          allow(user).to receive(:has_paid_namespace?) { has_paid_namespace? }
        end

        let(:expected_result) { !has_paid_namespace? && user? && check_namespace_plan? && group_without_trial? }

        subject { helper.trials_allowed?(local_user) }

        it { is_expected.to eq(expected_result) }
      end
    end

    context 'with cache concerns', :use_clean_rails_redis_caching do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
        allow(user).to receive(:owns_group_without_trial?).and_return(true)
        allow(user).to receive(:has_paid_namespace?).and_return(false)
      end

      it 'uses cache for result on next running of the method same user' do
        expect(helper.trials_allowed?(user)).to eq(true)

        allow(user).to receive(:has_paid_namespace?).and_return(true)

        expect(helper.trials_allowed?(user)).to eq(true)
      end

      it 'does not find a different user in cache result on next running of the method' do
        expect(helper.trials_allowed?(user)).to eq(true)

        expect(helper.trials_allowed?(build(:user))).to eq(false)
      end
    end
  end

  describe '#user_badges_in_admin_section' do
    subject { helper.user_badges_in_admin_section(user) }

    before do
      allow(helper).to receive(:current_user).and_return(build(:user))
      allow(::Gitlab).to receive(:com?) { gitlab_com? }
    end

    context 'when Gitlab.com? is true' do
      let(:gitlab_com?) { true }

      before do
        allow(user).to receive(:using_license_seat?).and_return(true)
      end

      context 'when user is an admin and the current_user' do
        before do
          allow(helper).to receive(:current_user).and_return(user)
          allow(user).to receive(:admin?).and_return(true)
        end

        it do
          expect(subject).to eq(
            [
              { text: 'Admin', variant: 'success' },
              { text: "It's you!", variant: 'muted' }
            ]
          )
        end
      end

      it { expect(subject).not_to eq([text: 'Is using seat', variant: 'light']) }
    end

    context 'when Gitlab.com? is false' do
      let(:gitlab_com?) { false }

      context 'when user uses a license seat' do
        before do
          allow(user).to receive(:using_license_seat?).and_return(true)
        end

        context 'when user is an admin and the current_user' do
          before do
            allow(helper).to receive(:current_user).and_return(user)
            allow(user).to receive(:admin?).and_return(true)
          end

          it do
            expect(subject).to eq(
              [
                { text: 'Admin', variant: 'success' },
                { text: 'Is using seat', variant: 'neutral' },
                { text: "It's you!", variant: 'muted' }
              ]
            )
          end
        end

        it { expect(subject).to eq([text: 'Is using seat', variant: 'neutral']) }
      end

      context 'when user does not use a license seat' do
        before do
          allow(user).to receive(:using_license_seat?).and_return(false)
        end

        it { expect(subject).to eq([]) }
      end
    end
  end

  describe '#display_public_email?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:scim_identity) { create(:scim_identity, group: group) }

    let(:user) { create(:user, :public_email, provisioned_by_group: scim_identity.group) }

    subject { helper.display_public_email?(user) }

    before do
      stub_feature_flags hide_public_email_on_profile: false
    end

    it { is_expected.to be true }

    context 'when public_email is blank' do
      before do
        user.update!(public_email: '')
      end

      it { is_expected.to be false }
    end

    context 'when provisioned_by_group is nil' do
      before do
        user.update!(provisioned_by_group: nil)
      end

      it { is_expected.to be true }
    end

    context 'when hide_public_email_on_profile is true' do
      before do
        stub_feature_flags hide_public_email_on_profile: true
      end

      it { is_expected.to be false }
    end
  end

  describe '#impersonation_enabled?' do
    subject { helper.impersonation_enabled? }

    context 'when impersonation is enabled' do
      before do
        stub_config_setting(impersonation_enabled: true)
      end

      it { is_expected.to eq(true) }

      context 'when personal access tokens are disabled' do
        before do
          stub_ee_application_setting(personal_access_tokens_disabled?: true)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when impersonation is disabled' do
      before do
        stub_config_setting(impersonation_enabled: false)
      end

      it { is_expected.to eq(false) }
    end
  end
end
