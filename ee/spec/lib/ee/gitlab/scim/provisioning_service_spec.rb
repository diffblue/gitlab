# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::Gitlab::Scim::ProvisioningService, feature_category: :system_access do
  include LoginHelpers

  describe '#execute' do
    let(:service) { described_class.new(service_params) }
    let_it_be(:service_params) do
      {
        email: 'work@example.com',
        name: 'Test Name',
        extern_uid: 'test_uid',
        username: 'username'
      }
    end

    shared_examples 'success response' do
      it 'contains a success status' do
        expect(service.execute.status).to eq(:success)
      end

      it 'contains an identity in the response' do
        expect(service.execute.identity).to be_a(Identity).or be_a(ScimIdentity)
      end
    end

    it 'creates the SCIM identity' do
      expect { service.execute }.to change { ScimIdentity.count }.by(1)
    end

    it 'does not creates the SAML identity' do
      expect { service.execute }.not_to change { Identity.count }
    end

    context 'when valid params' do
      let_it_be(:service_params) do
        {
          email: 'work@example.com',
          name: 'Test Name',
          extern_uid: 'test_uid',
          username: 'username'
        }
      end

      def user
        User.find_by(email: service_params[:email])
      end

      it_behaves_like 'success response'

      it 'creates the user' do
        expect { service.execute }.to change { User.count }.by(1)
      end

      it 'creates the correct user attributes' do
        service.execute

        expect(user).to be_a(User)
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

      context 'when invalid user params' do
        let_it_be(:service_params) do
          {
            email: 'work@example.com',
            name: 'Test Name',
            extern_uid: '',
            username: ''
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
    end

    context 'for an existing user' do
      before do
        create(:email, :confirmed, user: user, email: 'work@example.com')
      end

      let(:user) { create(:user) }

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
    end
  end
end
