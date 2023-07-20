# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EnterpriseUsers::DisassociateService, :saas, feature_category: :user_management do
  subject(:service) { described_class.new(user: user) }

  describe '#execute' do
    shared_examples 'disassociates the user from the enterprise group' do
      it 'returns a successful response', :aggregate_failures do
        response = service.execute

        expect(response.success?).to eq(true)
        expect(response.payload[:group]).to eq(group)
        expect(response.payload[:user]).to eq(user)
      end

      it 'sets user.user_detail.enterprise_group_id from group.id to nil' do
        expect(user.user_detail.enterprise_group_id).to eq(group.id)

        service.execute

        user.reload

        expect(user.user_detail.enterprise_group_id).to eq(nil)
      end

      it 'sets user.user_detail.enterprise_group_associated_at to nil' do
        expect(user.user_detail.enterprise_group_associated_at).not_to eq(nil)

        service.execute

        user.reload

        expect(user.user_detail.enterprise_group_associated_at).to eq(nil)
      end

      it 'logs message with info level about disassociating the user from the enterprise group' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          class: service.class.name,
          group_id: group.id,
          user_id: user.id,
          message: 'Disassociated the user from the enterprise group'
        )

        service.execute
      end

      context 'when the user detail update fails' do
        before do
          user.user_detail.pronouns = 'x' * 51
        end

        it 'raises active record error' do
          expect(Gitlab::AppLogger).not_to receive(:info)

          expect { subject.execute }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    shared_examples 'does not disassociate the user from the enterprise group' do |error_message, reason = nil|
      it 'returns a failed response', :aggregate_failures do
        response = service.execute

        expect(response.error?).to eq(true)
        expect(response.message).to eq(error_message)
        expect(response.reason).to eq(reason)
        expect(response.payload[:group]).to eq(group)
        expect(response.payload[:user]).to eq(user)
      end

      it 'does not update user.user_detail.enterprise_group_id' do
        previous_enterprise_group_id = user.user_detail.enterprise_group_id

        service.execute

        user.reload

        expect(user.user_detail.enterprise_group_id).to eq(previous_enterprise_group_id)
      end

      it 'does not update user.user_detail.enterprise_group_associated_at', :freeze_time do
        previous_enterprise_group_associated_at = user.user_detail.enterprise_group_associated_at

        service.execute

        user.reload

        expect(user.user_detail.enterprise_group_associated_at).to eq(previous_enterprise_group_associated_at)
      end

      it 'does not log any message with info level' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        service.execute
      end
    end

    context 'when the user is not an enterprise user' do
      let(:user) { create(:user) }
      let(:group) { nil }

      include_examples(
        'does not disassociate the user from the enterprise group',
        'The user is not an enterprise user'
      )
    end

    context 'when the user is an enterprise user' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:verified_domain) { create(:pages_domain, project: project) }
      let_it_be(:unverified_domain) { create(:pages_domain, :unverified, project: project) }

      let(:user_email_with_verified_domain) do
        create(:user, email: "example@#{verified_domain.domain}")
      end

      let(:user_email_with_unverified_domain) do
        create(:user, email: "example@#{unverified_domain.domain}")
      end

      before do
        stub_licensed_features(domain_verification: true)

        user.user_detail.update!(enterprise_group_id: group.id, enterprise_group_associated_at: Time.current)
      end

      context 'when the user matches the "Enterprise User" definition for the group' do
        let(:user) { user_email_with_verified_domain }

        include_examples(
          'does not disassociate the user from the enterprise group',
          'The user matches the "Enterprise User" definition for the group'
        )
      end

      context 'when the user does not match the "Enterprise User" definition for the group' do
        let(:user) { user_email_with_unverified_domain }

        include_examples 'disassociates the user from the enterprise group'
      end
    end
  end
end
