# frozen_string_literal: true

RSpec.shared_examples 'a collection filtered by test reports state' do
  describe '.with_last_test_report_state' do
    subject { described_class.with_last_test_report_state(state) }

    context 'for passed state' do
      let(:state) { 'passed' }

      it { is_expected.to contain_exactly(requirement2, requirement3) }
    end

    context 'for failed state' do
      let(:state) { 'failed' }

      it { is_expected.to contain_exactly(requirement1) }
    end
  end

  describe '.without_test_reports' do
    it 'returns requirements without test reports' do
      expect(described_class.without_test_reports).to contain_exactly(requirement4)
    end
  end
end
