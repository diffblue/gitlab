# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceFieldEntity do
  let(:request) { double('request') }

  subject { described_class.new(field, request: request, service: integration).as_json }

  before do
    allow(request).to receive(:service).and_return(integration)
  end

  describe '#as_json' do
    context 'GitHub Service' do
      let(:integration) { create(:github_integration) }

      context 'field with type checkbox' do
        let(:field) { integration_field('static_context') }

        it 'exposes correct attributes and casts value to Boolean' do
          expected_hash = {
            type: 'checkbox',
            name: 'static_context',
            title: 'Static status check names (optional)',
            placeholder: nil,
            required: nil,
            choices: nil,
            value: 'true',
            checkbox_label: 'Enable static status check names'
          }

          is_expected.to include(expected_hash)
        end
      end
    end
  end

  def integration_field(name)
    integration.global_fields.find { |f| f[:name] == name }
  end
end
