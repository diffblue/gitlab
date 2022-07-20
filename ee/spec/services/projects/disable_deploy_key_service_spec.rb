# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DisableDeployKeyService do
  let_it_be(:group) { create(:group) }
  let_it_be(:destination) { create(:external_audit_event_destination, group: group) }
  let_it_be(:deploy_key) { create(:deploy_key) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:deploy_key_project) { create(:deploy_keys_project, project: project, deploy_key: deploy_key) }
  let_it_be(:user) { project.creator }
  let_it_be(:params) { { id: deploy_key.id } }

  let_it_be(:service) { described_class.new(project, user, params) }

  before do
    stub_licensed_features(audit_events: true, external_audit_events: true)
  end

  it 'records an audit event' do
    expect { service.execute }.to change { AuditEvent.count }.by(1)

    audit_event = AuditEvent.last

    expect(audit_event.author_id).to eq(user.id)
    expect(audit_event.entity_id).to eq(project.id)
    expect(audit_event.entity_type).to eq(project.class.name)
    expect(audit_event.details).to include({
                                             remove: "deploy_key",
                                             author_name: user.name,
                                             custom_message: "Removed deploy key",
                                             target_details: deploy_key.title,
                                             target_type: "DeployKey"
                                           })
  end

  it_behaves_like 'sends correct event type in audit event stream' do
    let(:subject) { service.execute }

    let_it_be(:event_type) { "deploy_key_removed" }
  end
end
