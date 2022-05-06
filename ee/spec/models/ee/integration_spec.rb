# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integration do
  describe '.available_integration_names' do
    let(:include_saas_only) { true }

    subject { described_class.available_integration_names }

    before do
      allow(described_class).to receive(:integration_names).and_return(%w(foo saas_only))
      allow(described_class).to receive(:saas_only_integration_names).and_return(['saas_only'])
      allow(described_class).to receive(:include_saas_only?).and_return(include_saas_only)
    end

    it { is_expected.to include('foo', 'saas_only') }

    context 'when instance is not SaaS' do
      let(:include_saas_only) { false }

      it { is_expected.to include('foo') }
      it { is_expected.not_to include('saas_only') }
    end
  end

  describe '.project_specific_integration_names' do
    specify do
      stub_const("EE::#{described_class.name}::EE_PROJECT_SPECIFIC_INTEGRATION_NAMES", ['ee_project_specific_name'])

      expect(described_class.project_specific_integration_names)
        .to include('ee_project_specific_name')
    end
  end

  describe '.saas_only_integration_names' do
    specify do
      stub_const("EE::#{described_class.name}::EE_SAAS_ONLY_INTEGRATION_NAMES", ['ee_sass_only_name'])

      expect(described_class.saas_only_integration_names)
        .to eq(['ee_sass_only_name'])
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
