# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Headers::UpdateService, feature_category: :audit_events do
  let_it_be(:user) { create(:user) }
  let_it_be(:event_type) { "audit_events_streaming_headers_update" }

  let(:header) { create(:audit_events_streaming_header, key: 'old', value: 'old') }
  let(:destination) { header.external_audit_event_destination }
  let(:params) do
    {
      header: header,
      key: 'new',
      value: 'new'
    }
  end

  subject(:service) do
    described_class.new(
      current_user: user,
      destination: destination,
      params: params
    )
  end

  describe '#execute' do
    subject(:response) { service.execute }

    context 'when no header is provided' do
      let(:params) { super().merge( header: nil) }

      it 'does not update the header' do
        expect { subject }.not_to change { header.reload.key }
        expect(header.value).to eq 'old'
      end

      it 'has an error response' do
        expect(response).to be_error
        expect(response.errors).to match_array ['missing header param']
      end
    end

    it_behaves_like 'header updation' do
      let(:audit_scope) { destination.group }
      let(:extra_audit_context) { { stream_only: false } }
    end
  end
end
