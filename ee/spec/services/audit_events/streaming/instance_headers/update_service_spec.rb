# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::InstanceHeaders::UpdateService, feature_category: :audit_events do
  let(:header) { create(:instance_audit_events_streaming_header, key: 'old', value: 'old') }

  let(:params) do
    {
      header: header,
      key: 'new',
      value: 'new'
    }
  end

  subject(:service) do
    described_class.new(
      params: params
    )
  end

  describe '#execute' do
    subject(:response) { service.execute }

    it_behaves_like 'header updation'
  end
end
