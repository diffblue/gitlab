# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Headers::DestroyService, feature_category: :audit_events do
  let_it_be(:user) { create(:user) }
  let_it_be(:header) { create(:audit_events_streaming_header) }
  let_it_be(:event_type) { "audit_events_streaming_headers_destroy" }

  let(:destination) { header.external_audit_event_destination }
  let(:params) { { destination: destination, header: header } }

  subject(:service) do
    described_class.new(
      destination: destination,
      current_user: user,
      params: params
    )
  end

  describe '#execute' do
    let(:response) { service.execute }

    context 'when no header is provided' do
      let(:params) { super().merge( header: nil) }

      it 'does not destroy the header' do
        expect { response }.not_to change { destination.headers.count }
      end

      it 'has an error response' do
        response = service.execute

        expect(response).to be_error
        expect(response.errors).to match_array ['missing header param']
      end
    end

    it_behaves_like 'header deletion' do
      let(:audit_scope) { destination.group }
      let(:extra_audit_context) { { stream_only: false } }
    end
  end
end
