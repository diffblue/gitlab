# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Statistics::UpdateService, feature_category: :vulnerability_management do
  describe '.update_for' do
    let(:mock_service_object) { instance_double(described_class, execute: true) }
    let(:vulnerability) { instance_double(Vulnerability) }

    subject(:update_stats) { described_class.update_for(vulnerability) }

    before do
      allow(described_class).to receive(:new).with(vulnerability).and_return(mock_service_object)
    end

    it 'instantiates an instance of service class and calls execute on it' do
      update_stats

      expect(mock_service_object).to have_received(:execute)
    end
  end

  describe '#execute' do
    let_it_be(:project) { create(:project) }
    let_it_be(:statistic) { create(:vulnerability_statistic, project: project) }

    let(:vulnerability) { create(:vulnerability, severity: :high, project: project) }
    let(:stat_diff) { Vulnerabilities::StatDiff.new(vulnerability) }

    subject(:update_stats) { described_class.new(vulnerability).execute }

    context 'when the diff is empty' do
      it 'does not change existing statistic entity' do
        expect { update_stats }.not_to change { statistic.reload }
      end
    end

    context 'when the diff is not empty' do
      before do
        vulnerability.update_attribute(:severity, :critical)
      end

      context 'when there is already a record in the database' do
        it 'changes the existing statistic entity' do
          expect { update_stats }.to change { statistic.reload.critical }.by(1)
                                 .and not_change { statistic.reload.high }
        end
      end

      context 'when there is no existing record in the database' do
        before do
          statistic.destroy!
        end

        it 'creates a new record in the database' do
          expect { update_stats }.to change { Vulnerabilities::Statistic.count }.by(1)
        end
      end
    end
  end
end
