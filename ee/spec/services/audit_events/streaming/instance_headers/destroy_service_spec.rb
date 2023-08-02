# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::InstanceHeaders::DestroyService, feature_category: :audit_events do
  let_it_be(:header) { create(:instance_audit_events_streaming_header) }
  let_it_be(:user) { create(:admin) }
  let_it_be(:event_type) { "audit_events_streaming_instance_headers_destroy" }

  let(:destination) { header.instance_external_audit_event_destination }

  let(:params) { { header: header } }

  subject(:service) do
    described_class.new(
      params: params,
      current_user: user
    )
  end

  describe '#execute' do
    let(:response) { service.execute }

    it_behaves_like 'header deletion' do
      let(:audit_scope) { be_an_instance_of(Gitlab::Audit::InstanceScope) }
      let(:extra_audit_context) { {} }
    end
  end
end
