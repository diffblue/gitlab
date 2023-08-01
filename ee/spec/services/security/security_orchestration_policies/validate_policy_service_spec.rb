# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SecurityOrchestrationPolicies::ValidatePolicyService, feature_category: :security_policy_management do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let(:service) { described_class.new(container: container, params: { policy: policy, validate_approvals_required: validate_approvals_required }) }
    let(:validate_approvals_required) { true }
    let(:enabled) { true }
    let(:policy_type) { 'scan_execution_policy' }
    let(:name) { 'New policy' }
    let(:rule) { { agents: { production: {} } } }
    let(:rules) { [rule] }
    let(:policy) do
      {
        type: policy_type,
        name: name,
        enabled: enabled,
        rules: rules
      }
    end

    subject(:result) { service.execute }

    shared_examples 'checks only if policy is enabled' do
      let(:enabled) { false }

      it { expect(result[:status]).to eq(:success) }
    end

    shared_examples 'sets validation errors' do |message:, field: described_class::DEFAULT_VALIDATION_ERROR_FIELD, level: :error, title: nil|
      describe 'validation errors' do
        subject(:errors) { result[:validation_errors] }

        specify { expect(errors).to be_one }

        specify do
          expect(errors.first).to include(field: field, level: level, message: message, title: title || anything)
        end
      end
    end

    shared_examples 'checks policy type' do
      context 'when policy type is not provided' do
        let(:policy_type) { nil }

        it { expect(result[:status]).to eq(:error) }
        it { expect(result[:message]).to eq('Invalid policy') }
        it { expect(result[:details]).to match_array(['Invalid policy type']) }

        it_behaves_like 'sets validation errors', message: 'Invalid policy type'
      end

      context 'when policy type is invalid' do
        let(:policy_type) { 'invalid_policy_type' }

        it { expect(result[:status]).to eq(:error) }
        it { expect(result[:message]).to eq('Invalid policy') }
        it { expect(result[:details]).to match_array(['Invalid policy type']) }

        it_behaves_like 'sets validation errors', message: 'Invalid policy type'
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

        it_behaves_like 'sets validation errors', message: 'Empty policy name'
      end

      context 'when policy name is invalid' do
        let(:name) { '' }

        it { expect(result[:status]).to eq(:error) }
        it { expect(result[:message]).to eq('Invalid policy') }
        it { expect(result[:details]).to match_array(['Empty policy name']) }

        it_behaves_like 'sets validation errors', message: 'Empty policy name'
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

        context 'when branches and branch_type are missing' do
          using RSpec::Parameterized::TableSyntax

          where(:policy_type, :branches, :branch_type, :status, :details, :field) do
            'scan_result_policy'    | nil | nil | :success | nil                                                     | nil
            'scan_execution_policy' | nil | nil | :error   | ['Policy cannot be enabled without branch information'] | :branches
          end

          with_them do
            before do
              rule[:branches] = branches if branches
              rule[:branch_type] = branch_type if branch_type
            end

            it { expect(result[:status]).to eq(status) }
            it { expect(result[:details]).to eq(details) }

            it_behaves_like 'sets validation errors', field: :branches, message: 'Policy cannot be enabled without branch information' do
              before do
                skip if status != :error
              end
            end

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
            details: ['Required approvals exceed eligible approvers.'])
        end

        it_behaves_like 'sets validation errors',
          field: :approvers_ids,
          message: 'Required approvals exceed eligible approvers.',
          title: 'Logic error'
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

    shared_examples 'checks if branches exist for the provided branch_type' do
      let(:rule) do
        {
          branch_type: branch_type
        }
      end

      with_them do
        it { expect(result[:status]).to eq(status) }

        it 'returns a corresponding error message for error case' do
          if status == :error
            expect(result[:details]).to eq(["Branch types don't match any existing branches."])
          else
            expect(result[:details]).to be_nil
          end
        end

        it_behaves_like 'checks only if policy is enabled'
      end
    end

    shared_examples 'checks if timezone is valid' do
      context 'when timezone is not provided' do
        it { expect(result[:status]).to eq(:success) }
      end

      context 'when timezone is provided' do
        let(:rule) do
          {
            branches: ['master'],
            cadence: '0 0 * * *',
            timezone: timezone
          }
        end

        context 'when timezone is valid' do
          let(:timezone) { 'Europe/Amsterdam' }

          it { expect(result[:status]).to eq(:success) }
        end

        context 'when timezone valid ActiveSupport::TimeZone, but not TZInfo::Timezone' do
          let(:timezone) { 'Pacific Time (US & Canada)' }

          it_behaves_like 'sets validation errors', field: :timezone, message: 'Timezone is invalid'

          it { expect(result[:status]).to eq(:error) }
          it { expect(result[:details]).to match_array(['Timezone is invalid']) }
        end

        context 'when timezone is empty string' do
          let(:timezone) { '' }

          it_behaves_like 'sets validation errors', field: :timezone, message: 'Timezone is invalid'

          it { expect(result[:status]).to eq(:error) }
          it { expect(result[:details]).to match_array(['Timezone is invalid']) }
        end

        context 'when timezone is invalid' do
          let(:timezone) { 'invalid' }

          it_behaves_like 'sets validation errors', field: :timezone, message: 'Timezone is invalid'

          it { expect(result[:status]).to eq(:error) }
          it { expect(result[:details]).to match_array(['Timezone is invalid']) }
        end
      end
    end

    shared_examples 'checks if vulnerability_age is valid' do
      let(:policy_type) { 'scan_result_policy' }

      context 'when vulnerability_age is not provided' do
        it { expect(result[:status]).to eq(:success) }
      end

      context 'when vulnerability_age is provided' do
        let(:rule) do
          {
            branches: ['master'],
            vulnerability_states: vulnerability_states,
            vulnerability_age: {
              value: 1,
              interval: 'day',
              operator: 'less_than'
            }
          }
        end

        where(:vulnerability_states, :status) do
          nil                                       | :error
          []                                        | :error
          %w[new_needs_triage newly_detected]       | :error
          %w[detected new_needs_triage]             | :success
          %w[detected confirmed resolved dismissed] | :success
        end

        with_them do
          it { expect(result[:status]).to eq(status) }

          it 'returns a corresponding error message for error case' do
            if status == :error
              expect(result[:details]).to contain_exactly(/Vulnerability age requires previously existing/)
            else
              expect(result[:details]).to be_nil
            end
          end

          it_behaves_like 'sets validation errors', field: :vulnerability_age, message: /Vulnerability age requires previously existing/ do
            before do
              skip if status != :error
            end
          end
        end
      end
    end

    context 'when project or namespace is not provided' do
      let_it_be(:container) { nil }

      it_behaves_like 'checks policy type'
      it_behaves_like 'checks policy name'
      it_behaves_like 'checks if branches are provided in rule'
      it_behaves_like 'checks if timezone is valid'
      it_behaves_like 'checks if vulnerability_age is valid'
    end

    context 'when project is provided' do
      let_it_be(:default_branch) { 'master' }
      let_it_be(:protected_branch) { 'protected' }
      let_it_be(:unprotected_branch) { 'feature' }

      def setup_repository(project, branches)
        sha = project.repository.create_file(
          project.creator,
          "README.md",
          "",
          message: "initial commit",
          branch_name: branches.first)
        branches.each do |branch|
          project.repository.add_branch(project.creator, branch, sha)
        end
      end

      context 'when repository is empty' do
        let_it_be(:container) { create(:project, :empty_repo) }

        it_behaves_like 'checks policy type'
        it_behaves_like 'checks policy name'
        it_behaves_like 'checks if branches exist for the provided branch_type' do
          where(:policy_type, :branch_type, :status) do
            :scan_execution_policy | 'all' | :error
            :scan_execution_policy | 'protected' | :error
            :scan_execution_policy | 'default' | :error
            :scan_result_policy | 'protected' | :error
            :scan_result_policy | 'default' | :error
          end
        end
      end

      context 'when project has a default protected branch' do
        let_it_be(:container) { create(:project, :repository) }

        before_all do
          container.protected_branches.create!(name: 'master')
        end

        it_behaves_like 'checks policy type'
        it_behaves_like 'checks policy name'
        it_behaves_like 'checks if branches are provided in rule'
        it_behaves_like 'checks if branches are defined in the project'
        it_behaves_like 'checks if required approvals exceed eligible approvers'
        it_behaves_like 'checks if timezone is valid'
        it_behaves_like 'checks if vulnerability_age is valid'
        it_behaves_like 'checks if branches exist for the provided branch_type' do
          where(:policy_type, :branch_type, :status) do
            :scan_execution_policy | 'all' | :success
            :scan_execution_policy | 'protected' | :success
            :scan_execution_policy | 'default' | :success
            :scan_result_policy | 'protected' | :success
            :scan_result_policy | 'default' | :success
          end
        end
      end

      context 'when project has a non-default protected branch' do
        let_it_be(:container) { create(:project, :empty_repo) }

        before_all do
          setup_repository(container, [default_branch, protected_branch])
          container.protected_branches.create!(name: protected_branch)
        end

        it_behaves_like 'checks policy type'
        it_behaves_like 'checks policy name'
        it_behaves_like 'checks if branches are provided in rule'
        it_behaves_like 'checks if branches are defined in the project'
        it_behaves_like 'checks if required approvals exceed eligible approvers'
        it_behaves_like 'checks if timezone is valid'
        it_behaves_like 'checks if vulnerability_age is valid'
        it_behaves_like 'checks if branches exist for the provided branch_type' do
          where(:policy_type, :branch_type, :status) do
            :scan_execution_policy | 'all' | :success
            :scan_execution_policy | 'protected' | :success
            :scan_execution_policy | 'default' | :success
            :scan_result_policy | 'protected' | :success
            :scan_result_policy | 'default' | :error
          end
        end
      end

      context 'when project has only a default unprotected branch' do
        let_it_be(:container) { create(:project, :empty_repo) }

        before_all do
          setup_repository(container, [unprotected_branch])
        end

        it_behaves_like 'checks policy type'
        it_behaves_like 'checks policy name'
        it_behaves_like 'checks if branches exist for the provided branch_type' do
          where(:policy_type, :branch_type, :status) do
            :scan_execution_policy | 'all' | :success
            :scan_execution_policy | 'protected' | :error
            :scan_execution_policy | 'default' | :success
            :scan_result_policy | 'protected' | :error
            :scan_result_policy | 'default' | :error
          end

          context 'with multiple rules' do
            where(:branch_type1, :branch_type2, :status) do
              'protected' | 'default' | :error
              'all' | 'protected' | :error
              'all' | 'default' | :success
            end

            with_them do
              let(:rules) do
                [{ branch_type: branch_type1 }, { branch_type: branch_type2 }]
              end

              it { expect(result[:status]).to eq(status) }
            end
          end
        end
      end
    end

    context 'when namespace is provided' do
      let_it_be(:container) { create(:group) }

      it_behaves_like 'checks policy type'
      it_behaves_like 'checks policy name'
      it_behaves_like 'checks if branches are provided in rule'
      it_behaves_like 'checks if required approvals exceed eligible approvers'
      it_behaves_like 'checks if timezone is valid'
      it_behaves_like 'checks if vulnerability_age is valid'
    end
  end
end
