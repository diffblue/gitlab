# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EnterpriseUsers::CreateService, :saas, feature_category: :system_access do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: subgroup) }
  let_it_be(:verified_domain) { create(:pages_domain, project: project1) }
  let_it_be(:unverified_domain) { create(:pages_domain, :unverified, project: project2) }

  let(:user_created_at) { Time.utc(2021, 2, 1) - 1.second }

  let(:user_email_with_verified_domain) do
    create(:user, email: "example@#{verified_domain.domain}", created_at: user_created_at)
  end

  let(:user_email_with_unverified_domain) do
    create(:user, email: "example@#{unverified_domain.domain}", created_at: user_created_at)
  end

  let(:user) { create(:user, created_at: user_created_at) }

  subject(:service) { described_class.new(group: group, user: user) }

  before do
    group.add_guest(user)
  end

  describe '#execute' do
    shared_examples 'can mark the user as an enterprise user of the group' do
      it 'returns a successful response', :aggregate_failures do
        response = service.execute

        expect(response.success?).to eq(true)
        expect(response.payload[:group]).to eq(group)
        expect(response.payload[:user]).to eq(user)
      end

      it 'sets user.provisioned_by_group_id to group.id' do
        expect(user.provisioned_by_group_id).to eq(nil)

        service.execute

        expect(user.reload.provisioned_by_group_id).to eq(group.id)
      end

      it 'sets user.provisioned_by_group_at to Time.current', :freeze_time do
        expect(user.provisioned_by_group_at).to eq(nil)

        service.execute

        expect(user.reload.provisioned_by_group_at).to eq(Time.current)
      end

      it 'enqueues provisioned_member_access_granted_email email for later delivery to the user' do
        expect do
          service.execute
        end.to have_enqueued_mail(Notify, :provisioned_member_access_granted_email).with(group.member(user).id)
      end

      it 'logs message with info level about marking the user as an enterprise user of the group' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          class: service.class.name,
          group_id: group.id,
          user_id: user.id,
          message: 'Marked the user as an enterprise user of the group'
        )

        service.execute
      end

      context 'when the user detail cannot be updated' do
        before do
          user.user_detail.pronouns = 'x' * 51
        end

        include_examples(
          'does not mark the user as an enterprise user of the group',
          'The user detail cannot be updated', :user_detail_cannot_be_updated
        )
      end
    end

    shared_examples 'does not mark the user as an enterprise user of the group' do |error_message, reason = nil|
      it 'returns a failed response', :aggregate_failures do
        response = service.execute

        expect(response.error?).to eq(true)
        expect(response.message).to eq(error_message)
        expect(response.reason).to eq(reason)
        expect(response.payload[:group]).to eq(group)
        expect(response.payload[:user]).to eq(user)
      end

      it 'does not update user.provisioned_by_group_id' do
        previous_user_provisioned_by_group_id = user.provisioned_by_group_id

        service.execute

        expect(user.reload.provisioned_by_group_id).to eq(previous_user_provisioned_by_group_id)
      end

      it 'does not update user.provisioned_by_group_at' do
        previous_user_provisioned_by_group_at = user.provisioned_by_group_at

        service.execute

        expect(user.reload.provisioned_by_group_at).to eq(previous_user_provisioned_by_group_at)
      end

      it 'does not enqueue any email for later delivery' do
        expect do
          service.execute
        end.not_to have_enqueued_mail
      end

      it 'does not log any message with info level' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        service.execute
      end
    end

    context 'when the user is already an enterprise user of the group' do
      before do
        user.user_detail.update!(provisioned_by_group_id: group.id)
      end

      include_examples(
        'does not mark the user as an enterprise user of the group',
        'The user is already an enterprise user'
      )
    end

    context 'when the user is already an enterprise user of another group' do
      let_it_be(:group1) { create(:group) }

      before do
        user.user_detail.update!(provisioned_by_group_id: group1.id)
      end

      include_examples(
        'does not mark the user as an enterprise user of the group',
        'The user is already an enterprise user'
      )
    end

    context 'when the user is not a member of the group' do
      before do
        group.member(user).destroy!
      end

      include_examples(
        'does not mark the user as an enterprise user of the group',
        'The user is not a member of the group'
      )
    end

    include_examples(
      'does not mark the user as an enterprise user of the group',
      'The user does not match the "Enterprise User" definition for the group'
    )

    context 'when the domain_verification feature is licensed' do
      let(:gitlab_subscription_start_date) { Time.utc(2021, 2, 1) - 1.second }

      before do
        stub_licensed_features(domain_verification: true)

        create(:gitlab_subscription, :premium, namespace: group, start_date: gitlab_subscription_start_date)
      end

      include_examples(
        'does not mark the user as an enterprise user of the group',
        'The user does not match the "Enterprise User" definition for the group'
      )

      context "when the user's primary email has a domain that is owned by the company of the paid group" do
        let(:user) { user_email_with_verified_domain }

        include_examples(
          'does not mark the user as an enterprise user of the group',
          'The user does not match the "Enterprise User" definition for the group'
        )

        context 'when the user was created' do
          context 'when before 2021-02-01' do
            let(:user_created_at) { Time.utc(2021, 2, 1) - 1.second }

            include_examples(
              'does not mark the user as an enterprise user of the group',
              'The user does not match the "Enterprise User" definition for the group'
            )
          end

          context 'when at 2021-02-01' do
            let(:user_created_at) { Time.utc(2021, 2, 1) }

            include_examples 'can mark the user as an enterprise user of the group'
          end

          context 'when after 2021-02-01' do
            let(:user_created_at) { Time.utc(2021, 2, 1) + 1.day }

            include_examples 'can mark the user as an enterprise user of the group'
          end
        end

        context 'when the user has a SAML or SCIM identity tied to the group' do
          context 'when SAML identity' do
            let_it_be(:saml_provider) { create(:saml_provider, group: group) }
            let!(:group_saml_identity) { create(:group_saml_identity, saml_provider: saml_provider, user: user) }

            include_examples 'can mark the user as an enterprise user of the group'
          end

          context 'when SCIM identity' do
            let!(:scim_identity) { create(:scim_identity, group: group, user: user) }

            include_examples 'can mark the user as an enterprise user of the group'
          end
        end

        context "when the group's subscription was purchased or renewed" do
          context 'when before 2021-02-01' do
            let(:gitlab_subscription_start_date) { Time.utc(2021, 2, 1) - 1.second }

            include_examples(
              'does not mark the user as an enterprise user of the group',
              'The user does not match the "Enterprise User" definition for the group'
            )
          end

          context 'when at 2021-02-01' do
            let(:gitlab_subscription_start_date) { Time.utc(2021, 2, 1) }

            include_examples 'can mark the user as an enterprise user of the group'
          end

          context 'when after 2021-02-01' do
            let(:gitlab_subscription_start_date) { Time.utc(2021, 2, 1) + 1.day }

            include_examples 'can mark the user as an enterprise user of the group'
          end
        end
      end

      context "when the group is not owner of the user's primary email" do
        shared_examples 'does not mark the user as an enterprise user as ownership of the email cannot be proved' do
          context 'when the user was created' do
            context 'when after 2021-02-01' do
              let(:user_created_at) { Time.utc(2021, 2, 1) + 1.day }

              include_examples(
                'does not mark the user as an enterprise user of the group',
                'The user does not match the "Enterprise User" definition for the group'
              )
            end
          end

          context 'when the user has a SAML or SCIM identity tied to the group' do
            context 'when SAML identity' do
              let_it_be(:saml_provider) { create(:saml_provider, group: group) }
              let!(:group_saml_identity) { create(:group_saml_identity, saml_provider: saml_provider, user: user) }

              include_examples(
                'does not mark the user as an enterprise user of the group',
                'The user does not match the "Enterprise User" definition for the group'
              )
            end

            context 'when SCIM identity' do
              let!(:scim_identity) { create(:scim_identity, group: group, user: user) }

              include_examples(
                'does not mark the user as an enterprise user of the group',
                'The user does not match the "Enterprise User" definition for the group'
              )
            end
          end

          context "when the group's subscription was purchased or renewed" do
            context 'when after 2021-02-01' do
              let(:gitlab_subscription_start_date) { Time.utc(2021, 2, 1) + 1.day }

              include_examples(
                'does not mark the user as an enterprise user of the group',
                'The user does not match the "Enterprise User" definition for the group'
              )
            end
          end
        end

        context "as the company of the paid group hasn't verified the domain of the user's primary email" do
          let(:user) { user_email_with_unverified_domain }

          include_examples 'does not mark the user as an enterprise user as ownership of the email cannot be proved'
        end

        context 'as the domain_verification feature is not licensed for the group' do
          let(:user) { user_email_with_verified_domain }

          before do
            stub_licensed_features(domain_verification: false)
          end

          include_examples 'does not mark the user as an enterprise user as ownership of the email cannot be proved'
        end
      end
    end
  end
end
