# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::InstanceHeaders::DestroyService, feature_category: :audit_events do
  let_it_be(:header) { create(:instance_audit_events_streaming_header) }

  let(:destination) { header.instance_external_audit_event_destination }

  let(:params) { { header: header } }

  subject(:service) do
    described_class.new(
      params: params
    )
  end

  describe '#execute' do
    let(:response) { service.execute }

    it_behaves_like 'header deletion'
  end
end
