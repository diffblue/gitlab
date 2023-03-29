# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::User do
  let(:uid) { 1234 }
  let(:saml_provider) { create(:saml_provider) }
  let(:group) { saml_provider.group }
  let(:auth_hash) { OmniAuth::AuthHash.new(uid: uid, provider: 'group_saml', info: info_hash, extra: { raw_info: OneLogin::RubySaml::Attributes.new }) }
  let(:info_hash) do
    {
      name: generate(:name),
      email: generate(:email)
    }
  end

  subject(:oauth_user) do
    oauth_user = described_class.new(auth_hash)
    oauth_user.saml_provider = saml_provider

    oauth_user
  end

  def create_existing_identity
    create(:group_saml_identity, extern_uid: uid, saml_provider: saml_provider)
  end

  describe '#valid_sign_in?' do
    context 'with matching user for that group and uid' do
      let!(:identity) { create_existing_identity }

      it 'returns true' do
        is_expected.to be_valid_sign_in
      end
    end

    context 'with no matching user identity' do
      it 'returns false' do
        is_expected.not_to be_valid_sign_in
      end
    end
  end

  describe '#find_and_update!' do
    subject(:find_and_update) { oauth_user.find_and_update! }

    context 'with matching user for that group and uid' do
      let!(:identity) { create_existing_identity }

      it 'updates group membership' do
        expect { find_and_update }.to change { group.members.count }.by(1)
      end

      it 'returns the user' do
        expect(find_and_update).to eq identity.user
      end

      it 'does not mark the user as provisioned' do
        expect(find_and_update.provisioned_by_group).to be_nil
      end

      context 'when user attributes are present but the user is not provisioned' do
        before do
          identity.user.update!(can_create_group: false, projects_limit: 10)

          auth_hash[:extra][:raw_info] =
            OneLogin::RubySaml::Attributes.new(
              'can_create_group' => %w(true), 'projects_limit' => %w(20)
            )
        end

        it 'does not update the user can_create_group attribute' do
          expect(find_and_update.can_create_group).to eq(false)
        end

        it 'does not update the user projects_limit attribute' do
          expect(find_and_update.projects_limit).to eq(10)
        end
      end

      context 'when the user has multiple group saml identities' do
        let(:saml_provider2) { create(:saml_provider) }

        before do
          create(:group_saml_identity, extern_uid: uid, saml_provider: saml_provider2, user: identity.user)
        end

        it 'returns the user' do
          expect(find_and_update).to eq identity.user
        end
      end
    end

    context 'with no matching user identity' do
      context 'when a user does not exist' do
        it 'creates the user' do
          expect { find_and_update }.to change { User.count }.by(1)
        end

        it 'does not confirm the user' do
          is_expected.not_to be_confirmed
        end

        it 'returns the correct user' do
          expect(find_and_update.email).to eq info_hash[:email]
        end

        it 'marks the user as provisioned by the group' do
          expect(find_and_update.provisioned_by_group).to eq group
        end

        it 'does not set user.provisioned_by_group_at' do
          # This attribute is only set when a user becomes an enterprise user
          # based on domain verification. We want to
          # differentiate enterprise users provisioned by SCIM or SAML from
          # those who were made as enterprise users based on domain verification.
          # To know when users were provisioned by SCIM or SAML,
          # `User#created_at` should be used.
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/385785#note_1258055975
          expect(find_and_update.provisioned_by_group_at).to be_nil
        end

        it 'creates the user SAML identity' do
          expect { find_and_update }.to change { Identity.count }.by(1)
        end

        context 'when a verified pages domain matches the user email domain', :saas do
          before do
            stub_licensed_features(domain_verification: true)
            create(:pages_domain, project: create(:project, group: group), domain: info_hash[:email].split('@')[1])
          end

          it 'confirms the user' do
            expect(find_and_update).to be_confirmed
          end
        end

        context 'when user attributes are present' do
          before do
            auth_hash[:extra][:raw_info] =
              OneLogin::RubySaml::Attributes.new(
                'can_create_group' => %w(true), 'projects_limit' => %w(20)
              )
          end

          it 'creates the user with correct can_create_group attribute' do
            expect(find_and_update.can_create_group).to eq(true)
          end

          it 'creates the user with correct projects_limit attribute' do
            expect(find_and_update.projects_limit).to eq(20)
          end
        end

        it 'does not send user confirmation email' do
          expect { find_and_update }
            .not_to have_enqueued_mail(DeviseMailer, :confirmation_instructions)
        end
      end

      context 'when a conflicting user already exists' do
        let!(:user) { create(:user, email: info_hash[:email]) }

        it 'does not update membership' do
          expect { find_and_update }.not_to change { group.members.count }
        end

        it 'does not return a user' do
          expect(find_and_update).to eq nil
        end

        context 'when user was provisioned by this group' do
          before do
            user.update!(provisioned_by_group: group)
          end

          it 'updates membership' do
            expect { find_and_update }.to change { group.members.count }.by(1)
          end

          it 'returns a user' do
            expect(find_and_update).to eq user
          end

          it 'updates identity' do
            expect { find_and_update }.to change { user.group_saml_identities.count }.by(1)
          end

          context 'when user attributes are present' do
            before do
              user.update!(can_create_group: false, projects_limit: 10)

              auth_hash[:extra][:raw_info] =
                OneLogin::RubySaml::Attributes.new(
                  'can_create_group' => %w(true), 'projects_limit' => %w(20)
                )
            end

            it 'updates the user with correct can_create_group attribute' do
              expect(find_and_update.can_create_group).to eq(true)
            end

            it 'updates the user with correct projects_limit attribute' do
              expect(find_and_update.projects_limit).to eq(20)
            end
          end

          context 'without feature flag turned on' do
            before do
              stub_feature_flags(block_password_auth_for_saml_users: false)
            end

            it 'does not update membership' do
              expect { find_and_update }.not_to change { group.members.count }
            end

            it 'does not return a user' do
              expect(find_and_update).to eq nil
            end

            it 'does not update identity' do
              expect { find_and_update }.not_to change { user.group_saml_identities.count }
            end
          end
        end

        context 'when user was provisioned by different group' do
          before do
            user.update!(provisioned_by_group: create(:group))
          end

          it 'does not update membership' do
            expect { find_and_update }.not_to change { group.members.count }
          end

          it 'does not return a user' do
            expect(find_and_update).to eq nil
          end

          it 'does not update identity' do
            expect { find_and_update }.not_to change { user.group_saml_identities.count }
          end
        end
      end
    end
  end

  describe '#bypass_two_factor?' do
    it 'is false' do
      expect(subject.bypass_two_factor?).to eq false
    end
  end

  describe '#identity_verification_enabled?', feature_category: :insider_threat do
    it 'is false' do
      expect(subject.identity_verification_enabled?(anything)).to eq(false)
    end
  end
end
