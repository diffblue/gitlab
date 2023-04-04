# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::PerformanceScore, type: :model, feature_category: :value_stream_management do
  subject { build :dora_performance_score }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:project) }
  it { is_expected.to validate_presence_of(:date) }
  it { is_expected.to validate_uniqueness_of(:date).scoped_to(:project_id) }

  describe '.refresh!' do
    let_it_be(:project) { create :project }
    let(:date) { Date.today }
    let(:calculated_scores) do
      { 'deployment_frequency' => 'low',
        'lead_time_for_changes' => 'medium',
        'time_to_restore_service' => 'high',
        'change_failure_rate' => nil }
    end

    before do
      allow(Analytics::DoraPerformanceScoreCalculator)
        .to receive(:scores_for).with(project, date.beginning_of_month).and_return(calculated_scores)
    end

    it 'creates new record with calculated scores' do
      described_class.refresh!(project, date)

      expect(described_class.find_by(project: project,
        date: date.beginning_of_month)).to have_attributes(calculated_scores)
    end

    context 'when record already exists' do
      let!(:existing_record) { create :dora_performance_score, project: project, date: date.beginning_of_month }

      it 'updates existing one' do
        expect do
          described_class.refresh!(project, date)
        end.not_to change { described_class.count }

        expect(existing_record.reload).to have_attributes(calculated_scores)
      end
    end
  end
end
