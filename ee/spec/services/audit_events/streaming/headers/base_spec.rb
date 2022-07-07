# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Headers::Base do
  let(:header) { build_stubbed(:audit_events_streaming_header) }
  let(:destination) { header.external_audit_event_destination }

  subject(:service) do
    described_class.new(
      group: destination&.group,
      params: { destination: destination }
    )
  end

  describe '#execute' do
    subject(:response) { service.execute }

    context 'when destination is missing' do
      let(:destination) { nil }

      it 'returns an error' do
        expect(response).to be_error
        expect(response.errors).to match_array ['missing destination param']
      end
    end

    context 'when streaming_audit_event_headers feature flag is disabled' do
      before do
        stub_feature_flags(streaming_audit_event_headers: false)
      end

      it 'raises an exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
