# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::SecurityPolicy::AssignSecurityPolicyProject do
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  describe '#resolve' do
    let_it_be(:owner) { create(:user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, namespace: owner.namespace) }
    let_it_be(:policy_project) { create(:project) }
    let_it_be(:policy_project_id) { GitlabSchema.id_from_object(policy_project) }

    let(:current_user) { owner }

    subject { mutation.resolve(project_path: project.full_path, security_policy_project_id: policy_project_id) }

    context 'when permission is set for user' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when user is an owner of the project' do
        it 'assigns the security policy project' do
          result = subject

          expect(result[:errors]).to be_empty
          expect(project.security_orchestration_policy_configuration).not_to be_nil
          expect(project.security_orchestration_policy_configuration.security_policy_management_project).to eq(policy_project)
        end
      end

      context 'when user is not an owner' do
        let(:current_user) { user }

        before do
          project.add_maintainer(user)
        end

        it 'raises exception' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end

    context 'when policy_project_id is invalid' do
      let_it_be(:policy_project_id) { 'invalid' }

      it 'raises exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when feature is not licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
      end

      it 'raises exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
