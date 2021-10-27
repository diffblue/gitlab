# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::SecurityPolicy::UnassignSecurityPolicyProject do
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  describe '#resolve' do
    let_it_be(:owner) { create(:user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :with_security_orchestration_policy_configuration, namespace: owner.namespace) }
    let_it_be(:project_without_policy_project) { create(:project, namespace: owner.namespace) }

    let(:project_full_path) { project.full_path }
    let(:current_user) { owner }

    subject { mutation.resolve(project_path: project_full_path) }

    context 'when permission is set for user' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when user is an owner of the project' do
        context 'when policy project is assigned to a project' do
          it 'assigns the security policy project' do
            result = subject

            expect(result[:errors]).to be_empty
            expect(project.reload.security_orchestration_policy_configuration).to be_blank
          end
        end

        context 'when policy project is not assigned to a project' do
          let(:project_full_path) { project_without_policy_project.full_path }

          it 'respond with an error' do
            result = subject

            expect(result[:errors]).to match_array(["Policy project doesn't exist"])
          end
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
