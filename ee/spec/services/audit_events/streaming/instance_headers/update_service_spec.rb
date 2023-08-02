# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::InstanceHeaders::UpdateService, feature_category: :audit_events do
  let(:header) { create(:instance_audit_events_streaming_header, key: 'old', value: 'old') }
  let_it_be(:user) { create(:admin) }
  let_it_be(:event_type) { "audit_events_streaming_instance_headers_update" }

  let(:params) do
    {
      header: header,
      key: 'new',
      value: 'new'
    }
  end

  subject(:service) do
    described_class.new(
      params: params,
      current_user: user
    )
  end

  describe '#execute' do
    subject(:response) { service.execute }

    it_behaves_like 'header updation' do
      let(:audit_scope) { be_an_instance_of(Gitlab::Audit::InstanceScope) }
      let(:extra_audit_context) { {} }
    end
  end
end
