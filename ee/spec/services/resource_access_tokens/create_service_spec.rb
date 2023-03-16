# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceAccessTokens::CreateService, feature_category: :system_access do
  subject { described_class.new(user, resource).execute }

  let_it_be(:user) { create(:user) }

  before do
    stub_licensed_features(audit_events: true)
    stub_licensed_features(external_audit_events: true)
  end

  shared_examples 'token creation succeeds' do
    let(:resource) { create(:project, group: group) }

    before do
      resource.add_maintainer(user)
    end

    it 'does not cause an error' do
      response = subject

      expect(response.error?).to be false
    end

    it 'adds the project bot as a member' do
      expect { subject }.to change { resource.members.count }.by(1)
    end

    it 'creates a project bot user' do
      expect { subject }.to change { User.bots.count }.by(1)
    end
  end

  shared_examples 'audit event details' do
    it 'creates an audit event' do
      expect { subject }.to change { AuditEvent.count }.from(0).to(1)
    end

    it 'logs author and resource info', :aggregate_failures do
      subject

      audit_event = AuditEvent.where(author_id: user.id).last

      expect(audit_event.entity_id).to eq(resource.id)
      expect(audit_event.ip_address).to eq(user.current_sign_in_ip)
    end
  end

  describe '#execute' do
    context 'with enforced group managed account enabled' do
      let(:group) { create(:group_with_managed_accounts, :private) }
      let(:user) { create(:user, :group_managed, managing_group: group) }

      before do
        stub_feature_flags(group_managed_accounts: true)
        stub_licensed_features(group_saml: true)
      end

      it_behaves_like 'token creation succeeds'
    end

    context "for SAML enabled groups" do
      let(:group) { create(:group, :private) }
      let!(:saml_provider) { create(:saml_provider, group: group, enforced_sso: true) }
      let(:identity) { create(:group_saml_identity, saml_provider: saml_provider) }
      let(:user) { identity.user }

      before do
        stub_licensed_features(group_saml: true)
      end

      it_behaves_like 'token creation succeeds'
    end

    context 'project access token audit events' do
      let(:group) { create(:group) }
      let!(:destination) { create(:external_audit_event_destination, group: group) }
      let(:resource) { create(:project, group: group) }

      context 'when project access token is successfully created' do
        before do
          resource.add_maintainer(user)
        end

        it_behaves_like 'audit event details'

        it 'logs project access token details', :aggregate_failures do
          response = subject

          audit_event = AuditEvent.where(author_id: user.id).last
          access_token = response.payload[:access_token]
          custom_message = <<~MESSAGE.squish
            Created project access token with token_id: #{access_token.id} with scopes: #{access_token.scopes} and Maintainer access level.
          MESSAGE

          expect(audit_event.details).to include(
            custom_message: custom_message,
            target_id: access_token.id,
            target_type: access_token.class.name,
            target_details: access_token.user.name
          )
        end

        it_behaves_like 'sends correct event type in audit event stream' do
          let_it_be(:event_type) { "project_access_token_created" }
        end
      end

      context 'when project access token is unsuccessfully created' do
        context 'with inadequate permissions' do
          before do
            resource.add_developer(user)
          end

          it_behaves_like 'audit event details'

          it 'logs the permission error message' do
            subject

            audit_event = AuditEvent.where(author_id: user.id).last
            custom_message = <<~MESSAGE.squish
              Attempted to create project access token but failed with message:
              User does not have permission to create project access token
            MESSAGE

            expect(audit_event.details).to include(
              custom_message: custom_message,
              target_id: nil,
              target_type: nil,
              target_details: nil
            )
          end

          it_behaves_like 'sends correct event type in audit event stream' do
            let_it_be(:event_type) { "project_access_token_creation_failed" }
          end
        end

        context "when access provisioning fails" do
          let_it_be(:user) { create(:user) }

          let(:unpersisted_member) { build(:project_member, source: resource, user: user) }

          before do
            allow_next_instance_of(ResourceAccessTokens::CreateService) do |service|
              allow(service).to receive(:create_user).and_return(user)
              allow(service).to receive(:create_membership).and_return(unpersisted_member)
            end

            allow(unpersisted_member).to receive_message_chain(:errors, :full_messages, :to_sentence)
              .and_return('error message')

            resource.add_maintainer(user)
          end

          it_behaves_like 'audit event details'

          it 'logs the provisioning error message' do
            subject

            audit_event = AuditEvent.where(author_id: user.id).last
            custom_message = <<~MESSAGE.squish
              Attempted to create project access token but failed with message:
              Could not provision maintainer access to the access token. ERROR: error message
            MESSAGE

            expect(audit_event.details).to include(
              custom_message: custom_message,
              target_id: nil,
              target_type: nil,
              target_details: nil
            )
          end

          it_behaves_like 'sends correct event type in audit event stream' do
            let_it_be(:event_type) { "project_access_token_creation_failed" }
          end
        end
      end
    end
  end
end
