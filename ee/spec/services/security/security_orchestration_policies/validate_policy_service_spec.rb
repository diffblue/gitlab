# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ValidatePolicyService do
  describe '#execute' do
    let(:service) { described_class.new(project: project, params: { policy: policy }) }
    let(:enabled) { true }
    let(:policy_type) { 'scan_execution_policy' }
    let(:rule) { { clusters: { production: {} } } }
    let(:policy) do
      {
        type: policy_type,
        enabled: enabled,
        rules: [rule]
      }
    end

    subject(:result) { service.execute }

    shared_examples 'checks only if policy is enabled' do
      let(:enabled) { false }

      it { expect(result[:status]).to eq(:success) }
    end

    shared_examples 'checks policy type' do
      context 'when policy type is not provided' do
        let(:policy_type) { nil }

        it { expect(result[:status]).to eq(:error) }
        it { expect(result[:message]).to eq('Invalid policy type') }
      end

      context 'when policy type is invalid' do
        let(:policy_type) { 'invalid_policy_type' }

        it { expect(result[:status]).to eq(:error) }
        it { expect(result[:message]).to eq('Invalid policy type') }
      end

      context 'when policy type is valid' do
        it { expect(result[:status]).to eq(:success) }
      end
    end

    shared_examples 'checks if branches are provided in rule' do
      context 'when rule has clusters defined' do
        let(:rule) do
          {
            clusters: {
              production: {}
            },
            branches: branches
          }
        end

        context 'when branches are missing' do
          let(:branches) { nil }

          it { expect(result[:status]).to eq(:success) }
        end

        context 'when branches are provided' do
          let(:branches) { ['master'] }

          it { expect(result[:status]).to eq(:success) }
        end
      end

      context 'when rule does not have clusters defined' do
        let(:rule) do
          {
            branches: branches
          }
        end

        context 'when branches are missing' do
          let(:branches) { nil }

          it { expect(result[:status]).to eq(:error) }
          it { expect(result[:message]).to eq('Policy cannot be enabled without branch information') }

          it_behaves_like 'checks only if policy is enabled'
        end

        context 'when branches are provided' do
          let(:branches) { ['master'] }

          it { expect(result[:status]).to eq(:success) }
        end
      end
    end

    shared_examples 'checks if branches are defined in the project' do
      context 'when rule has clusters defined' do
        let(:rule) do
          {
            clusters: {
              production: {}
            },
            branches: branches
          }
        end

        context 'when branches are defined for project' do
          let(:branches) { ['master'] }

          it { expect(result[:status]).to eq(:success) }
        end

        context 'when branches are not defined for project' do
          let(:branches) { ['non-exising-branch'] }

          it { expect(result[:status]).to eq(:success) }
        end

        context 'when pattern does not match any branch defined for project' do
          let(:branches) { ['master', 'production-*', 'test-*'] }

          it { expect(result[:status]).to eq(:success) }
        end
      end

      context 'when rule does not have clusters defined' do
        let(:rule) do
          {
            branches: branches
          }
        end

        context 'when branches are defined for project' do
          let(:branches) { ['master'] }

          it { expect(result[:status]).to eq(:success) }
        end

        context 'when branches are not defined for project' do
          let(:branches) { ['non-exising-branch'] }

          it { expect(result[:status]).to eq(:error) }
          it { expect(result[:message]).to eq('Policy cannot be enabled for non-existing branches (non-exising-branch)') }

          it_behaves_like 'checks only if policy is enabled'
        end

        context 'when branches are defined as pattern' do
          context 'when pattern matches at least one branch defined for project' do
            let(:branches) { ['*'] }

            it { expect(result[:status]).to eq(:success) }
          end

          context 'when pattern does not match any branch defined for project' do
            let(:branches) { ['master', 'production-*', 'test-*'] }

            it { expect(result[:status]).to eq(:error) }
            it { expect(result[:message]).to eq('Policy cannot be enabled for non-existing branches (production-*, test-*)') }

            it_behaves_like 'checks only if policy is enabled'
          end
        end
      end
    end

    context 'when project is not provided' do
      let_it_be(:project) { nil }

      it_behaves_like 'checks policy type'
      it_behaves_like 'checks if branches are provided in rule'
    end

    context 'when project is provided' do
      let_it_be(:project) { create(:project, :repository) }

      it_behaves_like 'checks policy type'
      it_behaves_like 'checks if branches are provided in rule'
      it_behaves_like 'checks if branches are defined in the project'
    end
  end
end
