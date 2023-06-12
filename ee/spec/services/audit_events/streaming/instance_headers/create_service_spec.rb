# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::InstanceHeaders::CreateService, feature_category: :audit_events do
  let_it_be(:destination) { create(:instance_external_audit_event_destination) }
  let(:params) { { destination: destination } }

  subject(:service) do
    described_class.new(
      params: params
    )
  end

  describe '#execute' do
    subject(:response) { service.execute }

    it_behaves_like 'header creation validation errors'

    context 'when the header is created successfully' do
      let(:params) { super().merge(key: 'a_key', value: 'a_value') }

      it_behaves_like 'header creation successful'
    end
  end
end
