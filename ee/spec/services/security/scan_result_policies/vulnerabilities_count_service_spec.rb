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
  let(:vulnerability_age) { {} }
  let(:allowed_count) { 10 }

  subject(:service_result) do
    described_class.new(project: project, uuids: uuids, states: states,
      allowed_count: allowed_count, vulnerability_age: vulnerability_age).execute
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

    context 'when vulnerability_age is set' do
      let(:age_value) { 1 }
      let(:vulnerability_age) { { operator: operator, interval: interval, value: age_value } }

      shared_examples 'vulnerabilities detected in the desired age' do
        it 'returns a positive count' do
          expect(service_result[:count]).to eq(5)
        end
      end

      shared_examples 'vulnerabilities not detected in the desired age' do
        it 'returns a count of 0 vulnerabilities' do
          expect(service_result[:count]).to eq(0)
        end
      end

      shared_examples 'counting vulnerabilities detected in the interval' do
        context 'when counting vulnerabilities detected in the desired age' do
          let(:operator) { :greater_than }

          context 'when the vulnerabilities were detected in the selected age' do
            before do
              Vulnerability.update_all(created_at: 2.years.ago)
            end

            it_behaves_like 'vulnerabilities detected in the desired age'
          end

          context 'when the vulnerabilities were not detected in the selected age' do
            it_behaves_like 'vulnerabilities not detected in the desired age'
          end
        end

        context 'when counting vulnerabilities created before the desired age' do
          let(:operator) { :less_than }

          context 'when the vulnerabilities were not detected in the selected age' do
            it_behaves_like 'vulnerabilities detected in the desired age'
          end

          context 'when the vulnerabilities were detected in the selected age' do
            before do
              Vulnerability.update_all(created_at: 2.years.ago)
            end

            it_behaves_like 'vulnerabilities not detected in the desired age'
          end
        end
      end

      context 'when interval is in days' do
        let(:interval) { :day }

        it_behaves_like 'counting vulnerabilities detected in the interval'
      end

      context 'when interval is in weeks' do
        let(:interval) { :week }

        it_behaves_like 'counting vulnerabilities detected in the interval'
      end

      context 'when interval is in months' do
        let(:interval) { :month }

        it_behaves_like 'counting vulnerabilities detected in the interval'
      end

      context 'when interval is in years' do
        let(:interval) { :year }

        it_behaves_like 'counting vulnerabilities detected in the interval'
      end

      shared_examples 'ignores vulnerability age attributes' do
        it 'returns vulnerabilities count' do
          expect(service_result[:count]).to eq(5)
        end
      end

      context 'when interval is invalid' do
        let(:operator) { :greater_than }
        let(:interval) { :invalid_interval }

        it_behaves_like 'ignores vulnerability age attributes'
      end

      context 'when operator is invalid' do
        let(:operator) { :invalid_operator }
        let(:interval) { :year }

        it_behaves_like 'ignores vulnerability age attributes'
      end

      context 'when age value is invalid' do
        let(:operator) { :less_than }
        let(:interval) { :year }
        let(:age_value) { 'invalid age value' }

        it_behaves_like 'ignores vulnerability age attributes'
      end
    end
  end
end
