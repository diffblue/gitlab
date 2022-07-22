# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Headers::Base do
  let(:header) { build_stubbed(:audit_events_streaming_header) }
  let(:destination) { header.external_audit_event_destination }

  subject(:service) { described_class.new( destination: destination) }

  describe '#execute' do
    subject(:response) { service.execute }

    context 'when destination is missing' do
      let(:destination) { nil }

      it 'returns an error' do
        expect(response).to be_error
        expect(response.errors).to match_array ['missing destination param']
      end
    end
  end
end
