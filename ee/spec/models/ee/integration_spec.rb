# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integration do
  describe '.available_integration_names' do
    it { expect(described_class.available_integration_names).to include('github') }
  end

  describe '.project_specific_integration_names' do
    before do
      allow(::Gitlab).to receive(:com?).and_return(com)
    end

    context 'when not on gitlab.com' do
      let(:com) { false }

      it do
        expect(described_class.project_specific_integration_names)
          .to include(*described_class::EE_PROJECT_SPECIFIC_INTEGRATION_NAMES)
      end
    end

    context 'when on gitlab.com' do
      let(:com) { true }

      it do
        expect(described_class.project_specific_integration_names)
          .to include(*described_class::EE_PROJECT_SPECIFIC_INTEGRATION_NAMES, *Integration::EE_COM_PROJECT_SPECIFIC_INTEGRATION_NAMES)
      end
    end
  end

  describe '.vulnerability_hooks' do
    it 'includes services where vulnerability_events is true' do
      create(:service, active: true, vulnerability_events: true)

      expect(described_class.vulnerability_hooks.count).to eq 1
    end

    it 'excludes services where vulnerability_events is false' do
      create(:service, active: true, vulnerability_events: false)

      expect(described_class.vulnerability_hooks.count).to eq 0
    end
  end
end
