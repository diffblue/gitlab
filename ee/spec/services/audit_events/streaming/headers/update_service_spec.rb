# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Headers::UpdateService do
  let_it_be(:header) { create(:audit_events_streaming_header, key: 'old', value: 'old') }

  let(:destination) { header.external_audit_event_destination }
  let(:params) do
    {
      destination: destination,
      header: header,
      key: 'new',
      value: 'new'
    }
  end

  subject(:service) do
    described_class.new(
      group: destination&.group,
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

    context 'when the header is updated successfully' do
      it 'updates the header' do
        expect(response).to be_success
        expect(header.reload.key).to eq 'new'
        expect(header.value).to eq 'new'
      end
    end
  end
end
