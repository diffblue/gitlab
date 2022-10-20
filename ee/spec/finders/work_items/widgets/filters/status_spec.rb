# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Filters::Status do
  describe '.filter' do
    let_it_be(:work_item) { create(:work_item, :requirement, description: 'A description') }
    let_it_be(:work_item1) { create(:work_item, :satisfied_status) }
    let_it_be(:work_item2) { create(:work_item, :failed_status) }
    let_it_be(:work_item3) { create(:work_item, :requirement) }

    let(:relation) { WorkItem.all }
    let(:filter) { { status_widget: { status: status } } }

    subject { described_class.filter(relation, filter) }

    context 'for passing status' do
      let(:status) { 'passed' }

      it { is_expected.to contain_exactly(work_item1) }
    end

    context 'for failed status' do
      let(:status) { 'failed' }

      it { is_expected.to contain_exactly(work_item2) }
    end

    context 'for missing status' do
      let(:status) { 'missing' }

      it { is_expected.to contain_exactly(work_item3, work_item) }
    end

    context 'when status parameter is nil' do
      let(:status) { nil }

      it { is_expected.to contain_exactly(work_item, work_item1, work_item2, work_item3) }
    end
  end
end
