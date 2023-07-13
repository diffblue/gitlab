# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::OrphanedRemediationsCleanupWorker, feature_category: :vulnerability_management, type: :job do
  before do
    # with findings
    create(:vulnerabilities_remediation, findings: create_list(:vulnerabilities_finding, 1))
    # without_findings
    create(:vulnerabilities_remediation, findings: [])
  end

  shared_examples 'removes all orphaned remediations' do
    it 'deletes remediations that do not have any findings' do
      start_count = Vulnerabilities::Remediation.count
      end_count = start_count - Vulnerabilities::Remediation.where.missing(:findings).count

      expect { perform }.to change { Vulnerabilities::Remediation.count }.from(start_count).to(end_count)
    end
  end

  describe '.perform' do
    subject(:perform) { described_class.new.perform }

    it_behaves_like 'removes all orphaned remediations'

    context 'when orphaned remediations span multiple batches' do
      before do
        stub_const("#{described_class}::BATCH_SIZE", 1)
        create_list(:vulnerabilities_remediation, 2, findings: [])
      end

      it_behaves_like 'removes all orphaned remediations'
    end
  end
end
