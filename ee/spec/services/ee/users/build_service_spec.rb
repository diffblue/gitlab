# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::BuildService, feature_category: :user_management do
  describe '#execute' do
    let(:params) do
      { name: 'John Doe', username: 'jduser', email: 'jd@example.com', password: 'mydummypass' }
    end

    context 'with an admin user' do
      let_it_be(:admin_user) { create(:admin) }

      let(:service) { described_class.new(admin_user, ActionController::Parameters.new(params).permit!) }

      context 'with identity' do
        let_it_be(:provider) { create(:saml_provider) }
        let(:identity_params) { { extern_uid: 'uid', provider: 'group_saml', saml_provider_id: provider.id } }

        before do
          params.merge!(identity_params)
        end

        it 'sets all allowed attributes' do
          expect(Identity).to receive(:new).with(hash_including(identity_params)).and_call_original
          expect(ScimIdentity).not_to receive(:new)

          service.execute
        end

        context 'with scim identity' do
          let_it_be(:group) { create(:group) }
          let_it_be(:scim_identity_params) { { extern_uid: 'uid', provider: 'group_scim', group_id: group.id } }

          before do
            params.merge!(scim_identity_params)
          end

          it 'passes allowed attributes to both scim and saml identity' do
            scim_params = scim_identity_params.dup
            scim_params.delete(:provider)

            expect(ScimIdentity).to receive(:new).with(hash_including(scim_params)).and_call_original
            expect(Identity).to receive(:new).with(hash_including(identity_params)).and_call_original

            service.execute
          end

          it 'marks the user as provisioned by group' do
            expect(service.execute.provisioned_by_group_id).to eq(group.id)
          end

          it 'does not set user.provisioned_by_group_at' do
            # This attribute is only set when a user becomes an enterprise user
            # based on domain verification. We want to
            # differentiate enterprise users provisioned by SCIM or SAML from
            # those who were made as enterprise users based on domain verification.
            # To know when users were provisioned by SCIM or SAML,
            # `User#created_at` should be used.
            # See https://gitlab.com/gitlab-org/gitlab/-/issues/385785#note_1258055975
            expect(service.execute.provisioned_by_group_at).to be_nil
          end
        end
      end

      context 'with auditor as allowed params' do
        let(:params) { super().merge(auditor: 1) }

        it 'sets auditor to true' do
          user = service.execute

          expect(user.auditor).to eq(true)
        end
      end

      context 'with provisioned by group param' do
        let(:group) { create(:group) }
        let(:params) { super().merge(provisioned_by_group_id: group.id) }

        it 'does not set provisioned by group' do
          user = service.execute

          expect(user.provisioned_by_group_id).to eq(nil)
        end

        context 'with service account user type' do
          before do
            params.merge!(user_type: 'service_account')
          end

          it 'allows provisioned by group id to be set' do
            user = service.execute

            expect(user.provisioned_by_group_id).to eq(group.id)
            expect(user.user_type).to eq('service_account')
          end
        end
      end

      context 'smartcard authentication enabled' do
        before do
          allow(Gitlab::Auth::Smartcard).to receive(:enabled?).and_return(true)
        end

        context 'smartcard params' do
          let(:subject) { '/O=Random Corp Ltd/CN=gitlab-user/emailAddress=gitlab-user@random-corp.org' }
          let(:issuer) { '/O=Random Corp Ltd/CN=Random Corp' }
          let(:smartcard_identity_params) do
            { certificate_subject: subject, certificate_issuer: issuer }
          end

          before do
            params.merge!(smartcard_identity_params)
          end

          it 'sets smartcard identity attributes' do
            expect(SmartcardIdentity).to(
              receive(:new)
                .with(hash_including(issuer: issuer, subject: subject))
                .and_call_original)

            service.execute
          end
        end

        context 'missing smartcard params' do
          it 'works as expected' do
            expect { service.execute }.not_to raise_error
          end
        end
      end

      context 'user signup cap' do
        let(:new_user_signups_cap) { 10 }

        before do
          allow(Gitlab::CurrentSettings).to receive(:new_user_signups_cap).and_return(new_user_signups_cap)
        end

        context 'when user signup cap is set' do
          it 'sets the user state to blocked_pending_approval' do
            user = service.execute

            expect(user).to be_blocked_pending_approval
          end
        end

        context 'when user signup cap is not set' do
          let(:new_user_signups_cap) { nil }

          it 'does not set the user state to blocked_pending_approval' do
            user = service.execute

            expect(user).to be_active
          end
        end
      end
    end
  end
end
