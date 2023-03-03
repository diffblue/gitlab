# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKeys::CreateService, feature_category: :continuous_delivery do
  let_it_be(:group) { create(:group) }
  let_it_be(:destination) { create(:external_audit_event_destination, group: group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:params) { attributes_for(:deploy_key) }

  subject { described_class.new(user, params).execute(project: project) }

  before do
    stub_licensed_features(audit_events: true, external_audit_events: true)
  end

  it "creates a deploy key" do
    expect { subject }.to change { DeployKey.where(params.merge(user: user)).count }.by(1)
  end

  it 'records an audit event', :aggregate_failures do
    expect { subject }.to change { AuditEvent.count }.by(1)
    audit_event = AuditEvent.last

    expect(audit_event.author_id).to eq(user.id)
    expect(audit_event.entity_id).to eq(project.id)
    expect(audit_event.entity_type).to eq(project.class.name)
    expect(audit_event.details).to include({
                                             add: "deploy_key",
                                             author_name: user.name,
                                             custom_message: "Added deploy key",
                                             target_details: params[:title],
                                             target_type: "DeployKey"
                                           })
  end

  it_behaves_like 'sends correct event type in audit event stream' do
    let_it_be(:event_type) { "deploy_key_added" }
  end
end
