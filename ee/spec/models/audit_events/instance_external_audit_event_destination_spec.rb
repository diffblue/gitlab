# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::InstanceExternalAuditEventDestination, feature_category: :audit_events do
  subject(:destination) { build(:instance_external_audit_event_destination) }

  it_behaves_like 'includes ExternallyDestinationable concern' do
    subject(:destination_without_verification_token) do
      create(:instance_external_audit_event_destination, verification_token: nil)
    end
  end

  it_behaves_like 'includes Limitable concern'

  describe '#headers_hash' do
    subject { destination.headers_hash }

    it do
      is_expected.to eq({ 'X-Gitlab-Event-Streaming-Token' => destination.verification_token })
    end
  end
end
