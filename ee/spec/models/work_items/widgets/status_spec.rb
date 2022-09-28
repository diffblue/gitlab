# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Status do
  let_it_be_with_reload(:work_item) { create(:work_item, :requirement, description: 'A description') }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:status) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:status) }
  end

  describe '#status' do
    subject { described_class.new(work_item).status }

    context 'when last test report status is `failed`' do
      before do
        create(:test_report, requirement_issue: work_item, state: :failed)
      end

      it { is_expected.to eq('failed') }
    end

    context 'when last test report status is `passed`' do
      before do
        create(:test_report, requirement_issue: work_item, state: :passed)
      end

      it { is_expected.to eq('satisfied') }
    end

    context 'when test report is not present' do
      it { is_expected.to eq('unverified') }
    end
  end
end
