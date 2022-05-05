# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::SecurityPolicy::UnassignSecurityPolicyProject do
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  describe '#resolve' do
    let_it_be(:owner) { create(:user) }
    let_it_be(:user) { create(:user) }
    let_it_be(:namespace) { create(:group, :with_security_orchestration_policy_configuration) }
    let_it_be(:namespace_without_policy_project) { create(:group) }
    let_it_be(:project) { create(:project, :with_security_orchestration_policy_configuration, namespace: owner.namespace) }
    let_it_be(:project_without_policy_project) { create(:project, namespace: owner.namespace) }

    let(:container_full_path) { container.full_path }
    let(:current_user) { owner }

    subject { mutation.resolve(full_path: container_full_path) }

    shared_examples 'unassigns security policy project' do
      context 'when permission is set for user' do
        before do
          stub_licensed_features(security_orchestration_policies: true)
        end

        context 'when user is an owner of the project' do
          context 'when policy project is assigned to a container' do
            it 'unassigns the security policy project' do
              result = subject

              expect(result[:errors]).to be_empty
              expect(container.reload.security_orchestration_policy_configuration).to be_blank
            end
          end

          context 'when policy project is not assigned to a container' do
            let(:container_full_path) { container_without_policy_project.full_path }

            it 'respond with an error' do
              result = subject

              expect(result[:errors]).to match_array(["Policy project doesn't exist"])
            end
          end
        end

        context 'when user is not an owner' do
          let(:current_user) { user }

          before do
            container.add_maintainer(user)
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

    context 'when both fullPath and projectPath are not provided' do
      subject { mutation.resolve({}) }

      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      it 'raises exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    context 'for project' do
      let(:container) { project }
      let(:container_without_policy_project) { project_without_policy_project }

      it_behaves_like 'unassigns security policy project'
    end

    context 'for namespace' do
      let(:container) { namespace }
      let(:container_without_policy_project) { namespace_without_policy_project }

      before do
        namespace.add_owner(owner)
        namespace_without_policy_project.add_owner(owner)
      end

      it_behaves_like 'unassigns security policy project'
    end
  end
end
