# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::SecurityPolicy::CommitScanExecutionPolicy do
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, namespace: user.namespace) }
    let_it_be(:namespace) { create(:group) }
    let_it_be(:project_policy_management_project) { create(:project, :repository, namespace: user.namespace) }
    let_it_be(:namespace_policy_management_project) { create(:project, :repository, namespace: namespace) }
    let_it_be(:operation_mode) { Types::MutationOperationModeEnum.enum[:append] }
    let_it_be(:policy_name) { 'Test Policy' }
    let_it_be(:policy_yaml) { build(:scan_execution_policy, name: policy_name).merge(type: 'scan_execution_policy').to_yaml }

    subject { mutation.resolve(full_path: container.full_path, name: policy_name, policy_yaml: policy_yaml, operation_mode: operation_mode) }

    shared_context 'commits scan execution policies' do
      context 'when permission is set for user' do
        before do
          container.add_maintainer(user)

          stub_licensed_features(security_orchestration_policies: true)
        end

        it 'returns branch name' do
          result = subject

          expect(result[:errors]).to be_empty
          expect(result[:branch]).not_to be_empty
        end
      end

      context 'when permission is not enabled' do
        before do
          stub_licensed_features(security_orchestration_policies: false)
        end

        it 'raises exception' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end

    context 'when both fullPath and projectPath are not provided' do
      subject { mutation.resolve(name: policy_name, policy_yaml: policy_yaml, operation_mode: operation_mode) }

      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      it 'raises exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    context 'for project' do
      let_it_be_with_refind(:policy_configuration) { create(:security_orchestration_policy_configuration, security_policy_management_project: project_policy_management_project, project: project) }

      let(:container) { project }

      it_behaves_like 'commits scan execution policies'
    end

    context 'for namespace' do
      let_it_be_with_refind(:policy_configuration) { create(:security_orchestration_policy_configuration, :namespace, security_policy_management_project: namespace_policy_management_project, namespace: namespace) }

      let(:container) { namespace }

      it_behaves_like 'commits scan execution policies'
    end
  end
end
