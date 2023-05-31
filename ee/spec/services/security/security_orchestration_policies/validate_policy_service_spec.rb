# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ValidatePolicyService, feature_category: :security_policy_management do
  describe '#execute' do
    let(:service) { described_class.new(container: container, params: { policy: policy, validate_approvals_required: validate_approvals_required }) }
    let(:validate_approvals_required) { true }
    let(:enabled) { true }
    let(:policy_type) { 'scan_execution_policy' }
    let(:name) { 'New policy' }
    let(:rule) { { agents: { production: {} } } }
    let(:policy) do
      {
        type: policy_type,
        name: name,
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
        it { expect(result[:message]).to eq('Invalid policy') }
        it { expect(result[:details]).to match_array(['Invalid policy type']) }
      end

      context 'when policy type is invalid' do
        let(:policy_type) { 'invalid_policy_type' }

        it { expect(result[:status]).to eq(:error) }
        it { expect(result[:message]).to eq('Invalid policy') }
        it { expect(result[:details]).to match_array(['Invalid policy type']) }
      end

      context 'when policy type is valid' do
        it { expect(result[:status]).to eq(:success) }
      end
    end

    shared_examples 'checks policy name' do
      context 'when policy name is not provided' do
        let(:name) { nil }

        it { expect(result[:status]).to eq(:error) }
        it { expect(result[:message]).to eq('Invalid policy') }
        it { expect(result[:details]).to match_array(['Empty policy name']) }
      end

      context 'when policy name is invalid' do
        let(:name) { '' }

        it { expect(result[:status]).to eq(:error) }
        it { expect(result[:message]).to eq('Invalid policy') }
        it { expect(result[:details]).to match_array(['Empty policy name']) }
      end

      context 'when policy name is valid' do
        it { expect(result[:status]).to eq(:success) }
      end
    end

    shared_examples 'checks if branches are provided in rule' do
      context 'when rule has agents defined' do
        let(:rule) do
          {
            agents: {
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

      context 'when rule does not have agents defined' do
        let(:rule) do
          {
            branches: branches
          }
        end

        context 'when branches are missing' do
          using RSpec::Parameterized::TableSyntax

          let(:branches) { nil }

          where(:policy_type, :status, :details) do
            'scan_result_policy'    | :success | nil
            'scan_execution_policy' | :error   | ['Policy cannot be enabled without branch information']
          end

          with_them do
            it { expect(result[:status]).to eq(status) }
            it { expect(result[:details]).to eq(details) }

            it_behaves_like 'checks only if policy is enabled'
          end
        end

        context 'when branches are provided' do
          let(:branches) { ['master'] }

          it { expect(result[:status]).to eq(:success) }
        end
      end
    end

    shared_examples 'checks if branches are defined in the project' do
      context 'when rule has agents defined' do
        let(:rule) do
          {
            agents: {
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

      context 'when rule does not have agents defined' do
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
          it { expect(result[:message]).to eq('Invalid policy') }
          it { expect(result[:details]).to match_array(['Policy cannot be enabled for non-existing branches (non-exising-branch)']) }

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
            it { expect(result[:message]).to eq('Invalid policy') }
            it { expect(result[:details]).to match_array(['Policy cannot be enabled for non-existing branches (production-*, test-*)']) }

            it_behaves_like 'checks only if policy is enabled'
          end
        end
      end
    end

    shared_examples 'checks if required approvals exceed eligible approvers' do
      let(:policy_type) { 'scan_result_policy' }
      let(:user) { create(:user) }

      before do
        container.users.delete_all
        container.add_developer(user)

        policy[:actions] = [action]
      end

      shared_examples 'fails validation' do
        specify do
          expect(result).to include(status: :error,
            message: 'Invalid policy',
            details: ['Required approvals exceed eligible approvers'])
        end

        describe 'validation errors' do
          let(:error) { result[:validation_errors].first }

          specify do
            expect(result[:validation_errors]).to contain_exactly(error)

            expect(error).to eq(field: 'approvers_ids',
              level: :error,
              message: 'Required approvals exceed eligible approvers',
              title: 'Logic error')
          end
        end
      end

      shared_examples 'passes validation' do
        specify do
          expect(result).to eq(status: :success)
        end
      end

      context 'with validation disabled' do
        let(:validate_approvals_required) { false }

        let(:action) do
          {
            type: 'require_approval',
            user_approvers: [user.username],
            approvals_required: 42
          }
        end

        it_behaves_like 'passes validation'
      end

      context 'with user_approvers' do
        let(:action) do
          {
            type: 'require_approval',
            user_approvers: [user.username]
          }
        end

        context 'with exceeding approvals_required' do
          before do
            action[:approvals_required] = 2
          end

          it_behaves_like 'fails validation'
        end

        context 'with sufficient approvals_required' do
          before do
            action[:approvals_required] = 1
          end

          it_behaves_like 'passes validation'
        end
      end

      context 'with group_approvers' do
        let(:group) { create(:group) }
        let(:action) do
          {
            type: 'require_approval',
            group_approvers: [group.name]
          }
        end

        before do
          group.add_developer(user)
        end

        context 'with exceeding approvals_required' do
          before do
            action[:approvals_required] = 2
          end

          it_behaves_like 'fails validation'
        end

        context 'with sufficient approvals_required' do
          before do
            action[:approvals_required] = 1
          end

          it_behaves_like 'passes validation'
        end
      end

      context 'with role_approvers' do
        let(:action) do
          {
            type: 'require_approval',
            role_approvers: %w[developer]
          }
        end

        context 'with exceeding approvals_required' do
          before do
            skip if container.is_a?(Group)

            action[:approvals_required] = 2
          end

          it_behaves_like 'fails validation'
        end

        context 'with sufficient approvals_required' do
          before do
            action[:approvals_required] = 1
          end

          it_behaves_like 'passes validation'
        end
      end

      context 'with compound approvals' do
        let(:group) { create(:group) }
        let(:other_user) { create(:user) }
        let(:action) do
          {
            type: 'require_approval',
            group_approvers: [group.name],
            user_approvers: [other_user.username]
          }
        end

        before do
          group.add_developer(user)
          container.add_developer(other_user)
        end

        context 'with exceeding approvals_required' do
          before do
            action[:approvals_required] = 3
          end

          it_behaves_like 'fails validation'
        end

        context 'with sufficient approvals_required' do
          before do
            action[:approvals_required] = 2
          end

          it_behaves_like 'passes validation'
        end
      end
    end

    context 'when project or namespace is not provided' do
      let_it_be(:container) { nil }

      it_behaves_like 'checks policy type'
      it_behaves_like 'checks if branches are provided in rule'
    end

    context 'when project is provided' do
      let_it_be(:container) { create(:project, :repository) }

      it_behaves_like 'checks policy type'
      it_behaves_like 'checks if branches are provided in rule'
      it_behaves_like 'checks if branches are defined in the project'
      it_behaves_like 'checks if required approvals exceed eligible approvers'
    end

    context 'when namespace is provided' do
      let_it_be(:container) { create(:group) }

      it_behaves_like 'checks policy type'
      it_behaves_like 'checks if branches are provided in rule'
      it_behaves_like 'checks if required approvals exceed eligible approvers'
    end
  end
end
