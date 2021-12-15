# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Unassigns scan execution policy project from a project' do
  include GraphqlHelpers

  let_it_be_with_refind(:owner) { create(:user) }
  let_it_be_with_refind(:user) { create(:user) }
  let_it_be_with_refind(:project) { create(:project, namespace: owner.namespace) }

  let(:current_user) { owner }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation
    variables = { project_path: project.full_path }

    graphql_mutation(:security_policy_project_unassign, variables) do
      <<-QL.strip_heredoc
        errors
      QL
    end
  end

  def mutation_response
    graphql_mutation_response(:security_policy_project_unassign)
  end

  context 'when licensed feature is available' do
    before do
      stub_licensed_features(security_orchestration_policies: true)
    end

    context 'when user is an owner of the project' do
      context 'when there is no security policy project assigned to the project' do
        it 'unassigns the security policy project', :aggregate_failures do
          expect { subject }.not_to change { ::Security::OrchestrationPolicyConfiguration.count }

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['errors']).to eq(["Policy project doesn't exist"])
        end
      end

      context 'when security policy project is assigned to the project' do
        let!(:security_policy_management_project) { create(:project, :repository, namespace: current_user.namespace) }
        let!(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project, security_policy_management_project: security_policy_management_project) }

        it 'unassigns the security policy project', :aggregate_failures do
          expect { subject }.to change { ::Security::OrchestrationPolicyConfiguration.count }.by(-1)

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['errors']).to be_empty
        end
      end
    end

    context 'when user is not an owner' do
      let(:current_user) { user }

      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'a mutation that returns top-level errors',
                errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end
  end

  context 'when feature is not licensed' do
    before do
      stub_licensed_features(security_orchestration_policies: false)
    end

    it_behaves_like 'a mutation that returns top-level errors',
                errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
  end
end
