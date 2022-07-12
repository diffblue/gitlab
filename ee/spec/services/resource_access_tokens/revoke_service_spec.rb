# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceAccessTokens::RevokeService do
  subject { described_class.new(user, resource, access_token).execute }

  let_it_be(:user) { create(:user) }
  let_it_be(:resource_bot) { create(:user, :project_bot) }

  let(:access_token) { create(:personal_access_token, user: resource_bot) }

  before do
    stub_licensed_features(audit_events: true)
    stub_licensed_features(external_audit_events: true)
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

  context 'project access token audit events' do
    let(:group) { create(:group) }
    let!(:destination) { create(:external_audit_event_destination, group: group) }
    let(:resource) { create(:project, group: group) }

    context 'when project access token is successfully revoked' do
      before do
        resource.add_maintainer(user)
        resource.add_maintainer(resource_bot)
      end

      it_behaves_like 'audit event details'

      it 'logs project access token details', :aggregate_failures do
        subject

        audit_event = AuditEvent.where(author_id: user.id).last

        expect(audit_event.details).to include(
          custom_message: match(/Revoked project access token with token_id: \d+/),
          target_id: access_token.id,
          target_type: access_token.class.name,
          target_details: access_token.user.name
        )
      end

      it_behaves_like 'sends correct event type in audit event stream' do
        let_it_be(:event_type) { "project_access_token_deleted" }
      end
    end

    context 'when project access token is unsuccessfully revoked' do
      context 'when access token does not belong to this project' do
        before do
          resource.add_maintainer(user)
        end

        it_behaves_like 'audit event details'

        it 'logs the find error message' do
          subject

          audit_event = AuditEvent.where(author_id: user.id).last
          custom_message = <<~MESSAGE.squish
            Attempted to revoke project access token with token_id: \\d+, but failed with message:
            Failed to find bot user
          MESSAGE

          expect(audit_event.details).to include(
            custom_message: match(custom_message),
            target_id: access_token.id,
            target_type: access_token.class.name,
            target_details: access_token.user.name
          )
        end

        it_behaves_like 'sends correct event type in audit event stream' do
          let_it_be(:event_type) { "project_access_token_deletion_failed" }
        end
      end

      context 'with inadequate permissions' do
        before do
          resource.add_developer(user)
          resource.add_maintainer(resource_bot)
        end

        it_behaves_like 'audit event details'

        it 'logs the permission error message' do
          subject

          audit_event = AuditEvent.where(author_id: user.id).last
          custom_message = <<~MESSAGE.squish
            Attempted to revoke project access token with token_id: \\d+, but failed with message:
            #{user.name} cannot delete #{access_token.user.name}
          MESSAGE

          expect(audit_event.details).to include(
            custom_message: match(custom_message),
            target_id: access_token.id,
            target_type: access_token.class.name,
            target_details: access_token.user.name
          )
        end

        it_behaves_like 'sends correct event type in audit event stream' do
          let_it_be(:event_type) { "project_access_token_deletion_failed" }
        end
      end
    end
  end
end
