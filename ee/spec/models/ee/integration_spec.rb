# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integration do
  describe '.project_specific_integration_names' do
    specify do
      stub_const("EE::#{described_class.name}::EE_PROJECT_SPECIFIC_INTEGRATION_NAMES", ['ee_project_specific_name'])

      expect(described_class.project_specific_integration_names)
        .to include('ee_project_specific_name')
    end
  end

  describe '.vulnerability_hooks' do
    it 'includes integrations where vulnerability_events is true' do
      create(:integration, active: true, vulnerability_events: true)

      expect(described_class.vulnerability_hooks.count).to eq 1
    end

    it 'excludes integrations where vulnerability_events is false' do
      create(:integration, active: true, vulnerability_events: false)

      expect(described_class.vulnerability_hooks.count).to eq 0
    end
  end
end
