# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Statistics::AdjustmentService, feature_category: :vulnerability_management do
  let_it_be_with_reload(:project) { create(:project) }

  describe '.execute' do
    let(:project_ids) { [1, 2, 3] }
    let(:mock_service_object) { instance_double(described_class, execute: true) }

    subject(:execute_for_project_ids) { described_class.execute(project_ids) }

    before do
      allow(described_class).to receive(:new).with([1, 2, 3]).and_return(mock_service_object)
    end

    it 'instantiates the service object for given project ids and calls `execute` on them' do
      execute_for_project_ids

      expect(mock_service_object).to have_received(:execute)
    end
  end

  describe '#execute' do
    let(:statistics) { project.vulnerability_statistic.reload.as_json(only: expected_statistics.keys) }
    let(:project_ids) { [project.id] }

    let(:expected_statistics) do
      {
        'total' => 2,
        'critical' => 1,
        'high' => 1,
        'medium' => 0,
        'low' => 0,
        'info' => 0,
        'unknown' => 0,
        'letter_grade' => 'f'
      }
    end

    subject(:adjust_statistics) { described_class.new(project_ids).execute }

    before do
      create(:vulnerability, :critical_severity, project: project)
      create(:vulnerability, :high_severity, project: project)
    end

    context 'when more than 1000 projects is provided' do
      let(:project_ids) { (1..1001).to_a }

      it 'raises error' do
        expect { adjust_statistics }.to raise_error(described_class::TooManyProjectsError, 'Cannot adjust statistics for more than 1000 projects')
      end
    end

    context 'when there is no vulnerability_statistic record for project' do
      before do
        Vulnerabilities::Statistic.where(project: project).delete_all
      end

      it 'creates a new record' do
        expect { adjust_statistics }.to change { Vulnerabilities::Statistic.count }.by(1)
      end

      it 'sets the correct values for the record' do
        adjust_statistics

        expect(statistics).to eq(expected_statistics)
      end
    end

    context 'when there is already a vulnerability_statistic record for project' do
      before do
        project.vulnerability_statistic ||= create(:vulnerability_statistic, project: project)
        Vulnerabilities::Statistic.where(project: project).update_all(critical: 0, total: 0)
      end

      it 'does not create a new record in database' do
        expect { adjust_statistics }.not_to change { Vulnerabilities::Statistic.count }
      end

      it 'sets the correct values for the record' do
        adjust_statistics

        expect(statistics).to eq(expected_statistics)
      end
    end
  end
end
