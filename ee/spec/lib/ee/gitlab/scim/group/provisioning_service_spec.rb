# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::Gitlab::Scim::Group::ProvisioningService, :saas,
               feature_category: :system_access do
  describe '#execute' do
    let(:group) { create(:group) }
    let_it_be(:service_params) do
      {
        email: 'work@example.com',
        name: 'Test Name',
        extern_uid: 'test_uid',
        username: 'username'
      }
    end

    let(:service) { described_class.new(service_params, group) }
    let(:enforced_sso) { false }
    let!(:saml_provider) do
      create(:saml_provider, group: group,
                             enforced_sso: enforced_sso,
                             default_membership_role: Gitlab::Access::DEVELOPER)
    end

    before do
      stub_licensed_features(group_saml: true)
    end

    shared_examples 'success response' do
      it 'contains a success status' do
        expect(service.execute.status).to eq(:success)
      end

      it 'contains an identity in the response' do
        expect(service.execute.identity).to be_a(Identity).or be_a(ScimIdentity)
      end
    end

    shared_examples 'existing user' do
      it 'does not create a new user' do
        expect { service.execute }.not_to change { User.count }
      end

      it_behaves_like 'success response'

      it 'creates the SCIM identity' do
        expect { service.execute }.to change { ScimIdentity.count }.by(1)
      end

      it 'does not create the SAML identity' do
        expect { service.execute }.not_to change { Identity.count }
      end
    end

    context 'when valid params' do
      def user
        User.find_by(email: service_params[:email])
      end

      it_behaves_like 'success response'

      it 'creates the user' do
        expect { service.execute }.to change { User.count }.by(1)
      end

      it 'creates the group member' do
        expect { service.execute }.to change { GroupMember.count }.by(1)
      end

      it 'creates the correct user attributes' do
        service.execute

        expect(user).to be_a(User)
      end

      context 'when access level is given for created group member' do
        let!(:saml_provider) do
          create(:saml_provider, group: group, default_membership_role: Gitlab::Access::DEVELOPER)
        end

        it 'sets the access level of the member as specified in saml_provider' do
          service.execute

          access_level = group.member(user).access_level

          expect(access_level).to eq(Gitlab::Access::DEVELOPER)
        end
      end

      it 'user record requires confirmation' do
        service.execute

        expect(user).to be_present
        expect(user).not_to be_confirmed
      end

      context 'when the current minimum password length is different from the default minimum password length' do
        before do
          stub_application_setting minimum_password_length: 21
        end

        it 'creates the user' do
          expect { service.execute }.to change { User.count }.by(1)
        end
      end

      context 'when a verified pages domain matches the user email domain' do
        before do
          stub_licensed_features(domain_verification: true)
          create(:pages_domain, project: create(:project, group: group), domain: 'example.com')
        end

        it 'creates a confirmed user' do
          service.execute

          expect(user).to be_present
          expect(user).to be_confirmed
        end
      end
    end

    context 'when a provisioning error occurs' do
      let(:result) { StandardError.new("testing error") }
      let(:log_params) do
        {
          error: result.class.name,
          message: "testing error"
        }
      end

      let(:logger) { described_class.new(service_params, group).send(:logger) }

      before do
        allow(service).to receive(:logger).and_return(logger)
      end

      it 'logs error to standard error' do
        allow(service).to receive(:create_user_and_member).and_raise(result)
        expect(logger).to receive(:error).with(hash_including(log_params))

        service.execute
      end
    end

    context 'when invalid params' do
      let_it_be(:service_params) do
        {
          email: 'work@example.com',
          name: 'Test Name',
          extern_uid: 'test_uid'
        }
      end

      it 'fails with error' do
        expect(service.execute.status).to eq(:error)
      end

      it 'fails with missing params' do
        expect(service.execute.message).to eq("Missing params: [:username]")
      end
    end

    it 'creates the SCIM identity' do
      expect { service.execute }.to change { ScimIdentity.count }.by(1)
    end

    it 'creates the SAML identity' do
      expect { service.execute }.to change { Identity.count }.by(1)
    end

    context 'for an existing user' do
      before do
        create(:email, :confirmed, user: user, email: 'work@example.com')
      end

      let(:user) { create(:user) }

      context 'when user is not a group member' do
        it_behaves_like 'existing user'

        it 'creates the group member' do
          expect { service.execute }.to change { GroupMember.count }.by(1)
        end

        context 'with enforced SSO' do
          let(:enforced_sso) { true }

          it 'does not create the group member' do
            expect { service.execute }.not_to change { GroupMember.count }
          end

          it 'does not create the SAML identity' do
            expect { service.execute }.not_to change { Identity.count }
          end

          it 'does not create the SCIM identity' do
            expect { service.execute }.not_to change { ScimIdentity.count }
          end
        end
      end

      context 'when user is an existing group member' do
        before do
          group.add_guest(user)
        end

        it_behaves_like 'existing user'

        it 'does not create the group member' do
          expect { service.execute }.not_to change { GroupMember.count }
        end

        context 'when invalid identity' do
          let_it_be(:service_params) do
            {
              email: 'work@example.com',
              name: 'Test Name',
              extern_uid: '',
              username: 'username'
            }
          end

          let(:provision_response) do
            ::EE::Gitlab::Scim::ProvisioningResponse.new(identity: nil,
                                                         status: :error,
                                                         message: "Extern uid can't be blank")
          end

          it 'does not return nil result' do
            expect(service.execute).not_to be_nil
          end

          it 'returns error response' do
            expect(service.execute.to_json).to eq(provision_response.to_json)
          end
        end

        context 'when error in create identity' do
          let(:error_response) { described_class.new(service_params, group).send(:error_response) }

          before do
            allow(service).to receive(:identity).and_return(nil)
          end

          it 'returns provision response error' do
            response = service.execute

            expect(response).to be_a(::EE::Gitlab::Scim::ProvisioningResponse)
            expect(response.as_json).to match(hash_including('status' => 'error',
                                                             'message' => /^undefined method `save' for nil:NilClass/,
                                                             'identity' => nil))
          end
        end
      end
    end
  end
end
