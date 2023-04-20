# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::InstanceExternalAuditEventDestination, feature_category: :audit_events do
  it_behaves_like 'includes ExternallyDestinationable concern' do
    subject(:destination) { build(:instance_external_audit_event_destination) }

    subject(:destination_without_verification_token) do
      create(:instance_external_audit_event_destination, verification_token: nil)
    end
  end

  it_behaves_like 'includes Limitable concern' do
    subject { build(:instance_external_audit_event_destination) }
  end
end
