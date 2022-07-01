# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::FieldEntity do
  let(:request) { EntityRequest.new(integration: integration) }

  subject { described_class.new(field, request: request, integration: integration).as_json }

  before do
    allow(request).to receive(:integration).and_return(integration)
  end

  describe '#as_json' do
    context 'with GitHub integration' do
      let(:integration) { create(:github_integration) }

      context 'with field with type checkbox' do
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
    integration.form_fields.find { |f| f[:name] == name }
  end
end
