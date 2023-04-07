# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::VulnerabilitiesCountService, feature_category: :security_policy_management do
  let_it_be(:uuids) { Array.new(5) { SecureRandom.uuid } }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ee_ci_pipeline, project: project) }
  let_it_be(:vulnerability_findings) do
    create_list(:vulnerabilities_finding, 5, project: project) do |finding, i|
      vulnerability = create(:vulnerability, project: project)
      finding.update_columns(vulnerability_id: vulnerability.id, uuid: uuids[i])
    end
  end

  let(:states) { %w[detected confirmed] }
  let(:allowed_count) { 10 }

  subject(:service_result) do
    described_class.new(pipeline: pipeline, uuids: uuids, states: states, allowed_count: allowed_count).execute
  end

  describe '#execute' do
    context 'when result_count is less than allowed count' do
      it 'returns count and does not exceed allowed count' do
        expect(service_result).to eq({ count: 5, exceeded_allowed_count: false })
      end
    end

    context 'when result_count is greater than allowed count' do
      let(:allowed_count) { 4 }

      it 'returns count and exceeds allowed count' do
        expect(service_result).to eq({ count: 5, exceeded_allowed_count: true })
      end

      context 'when batch iteration is not complete' do
        let(:allowed_count) { 1 }

        before do
          stub_const('Security::ScanResultPolicies::VulnerabilitiesCountService::COUNT_BATCH_SIZE', 1)
        end

        it 'returns count and exceeds allowed count' do
          expect(Vulnerabilities::Read).to receive(:by_uuid).twice.and_call_original

          service_result
        end
      end
    end
  end
end
