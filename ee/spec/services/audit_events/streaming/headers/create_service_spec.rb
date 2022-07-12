# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Headers::CreateService do
  let(:destination) { create(:external_audit_event_destination) }
  let(:params) { {} }

  subject(:service) do
    described_class.new(
      destination: destination,
      params: params
    )
  end

  describe '#execute' do
    subject(:response) { service.execute }

    context 'when there are validation issues' do
      let(:expected_errors) { ["Key can't be blank", "Value can't be blank"] }

      it 'has an array of errors in the response' do
        expect(response).to be_error
        expect(response.errors).to match_array expected_errors
      end
    end

    context 'when the header is created successfully' do
      let(:params) { super().merge( key: 'a_key', value: 'a_value') }

      it 'has the header in the response payload' do
        expect(response).to be_success
        expect(response.payload[:header].key).to eq 'a_key'
        expect(response.payload[:header].value).to eq 'a_value'
      end
    end
  end
end
