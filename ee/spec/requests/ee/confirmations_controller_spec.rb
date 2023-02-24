# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConfirmationsController, type: :request,
                                        feature_category: :system_access do
  describe "GET #show" do
    let_it_be_with_reload(:user) { create(:user, :unconfirmed) }
    let(:confirmation_token) { user.confirmation_token }

    subject(:perform_request) do
      get user_confirmation_path, params: { confirmation_token: confirmation_token }
    end

    context "when user is signed in" do
      before do
        sign_in(user)
      end

      it "sets event_type" do
        expect_next_instance_of(described_class) do |controller|
          expect(controller).to receive(:audit_changes).with(:email,
            hash_including(event_type: 'user_email_changed_and_user_signed_in'))
        end

        perform_request
      end
    end

    context 'when user is provisioned by group' do
      let(:token) { 'supersecrettoken' }
      let(:group) { create(:group, saml_discovery_token: token) }
      let(:scim_identity) { create(:scim_identity, group: group) }

      before do
        user.update!(provisioned_by_group: scim_identity.group)
      end

      it 'confirms the user and redirects to SSO login', :aggregate_failures do
        perform_request

        expect(response).to redirect_to(sso_group_saml_providers_path(group, token: token))
        expect(user.reload).to be_confirmed
      end
    end
  end
end
