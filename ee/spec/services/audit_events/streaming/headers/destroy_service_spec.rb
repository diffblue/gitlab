# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Headers::DestroyService do
  let(:header) { create(:audit_events_streaming_header) }
  let(:destination) { header.external_audit_event_destination }
  let(:params) { {  destination: destination, header: header } }

  subject(:service) { described_class.new(destination: destination, params: params ) }

  describe '#execute' do
    context 'when no header is provided' do
      let(:params) { super().merge( header: nil) }

      it 'does not destroy the header' do
        expect { service.execute }.not_to change { destination.headers.count }
      end

      it 'has an error response' do
        response = service.execute

        expect(response).to be_error
        expect(response.errors).to match_array ['missing header param']
      end
    end

    context 'when the header is destroyed successfully' do
      let(:response) { service.execute }

      it 'destroys the header' do
        expect { response }.to change { destination.headers.count }.by(-1)
        expect(response).to be_success
      end
    end
  end
end
