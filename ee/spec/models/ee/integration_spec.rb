# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integration do
  describe '.available_integration_names' do
    it { expect(described_class.available_integration_names).to include('github') }
  end

  describe '.project_specific_integration_names' do
    subject { described_class.project_specific_integration_names }

    before do
      allow(::Gitlab).to receive(:com?).and_return(com)
    end

    context 'when not on gitlab.com' do
      let(:com) { false }

      it { is_expected.to include(*described_class::EE_PROJECT_SPECIFIC_INTEGRATION_NAMES) }
      it { is_expected.not_to include(*described_class::EE_COM_PROJECT_SPECIFIC_INTEGRATION_NAMES) }

      context 'when on dev' do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
        end

        it { is_expected.to include(*described_class::EE_COM_PROJECT_SPECIFIC_INTEGRATION_NAMES) }
      end
    end

    context 'when on gitlab.com' do
      let(:com) { true }

      it { is_expected.to include(*described_class::EE_PROJECT_SPECIFIC_INTEGRATION_NAMES, *Integration::EE_COM_PROJECT_SPECIFIC_INTEGRATION_NAMES) }
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
