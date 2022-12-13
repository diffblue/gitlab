# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Assigns scan execution policy project to a project/namespace',
feature_category: :security_policy_management do
  include GraphqlHelpers

  let_it_be_with_refind(:owner) { create(:user) }
  let_it_be_with_refind(:maintainer) { create(:user) }
  let_it_be_with_refind(:project) { create(:project, namespace: owner.namespace) }
  let_it_be_with_refind(:namespace) { create(:group) }
  let_it_be_with_refind(:policy_project) { create(:project) }
  let_it_be_with_refind(:policy_project_id) { GitlabSchema.id_from_object(policy_project) }

  let(:current_user) { owner }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation
    variables = { full_path: container.full_path, security_policy_project_id: policy_project_id.to_s }

    graphql_mutation(:security_policy_project_assign, variables) do
      <<-QL.strip_heredoc
        errors
      QL
    end
  end

  def mutation_response
    graphql_mutation_response(:security_policy_project_assign)
  end

  shared_context 'assigns security policy project' do
    context 'when licensed feature is available' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when user is an owner of the container' do
        before do
          container.add_owner(owner)
        end

        it 'assigns the security policy project', :aggregate_failures do
          subject

          orchestration_policy_configuration = container.security_orchestration_policy_configuration

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['errors']).to be_empty
          expect(orchestration_policy_configuration.security_policy_management_project).to eq(policy_project)
        end
      end

      context 'when user is not an owner' do
        let(:current_user) { maintainer }

        before do
          project.add_maintainer(maintainer)
        end

        it_behaves_like 'a mutation that returns top-level errors',
                  errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
      end

      context 'when policy_project_id is invalid' do
        let_it_be_with_refind(:policy_project_id) { "gid://gitlab/Project/#{non_existing_record_id}" }

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

  context 'for project' do
    let(:container) { project }

    it_behaves_like 'assigns security policy project'
  end

  context 'for namespace' do
    let(:container) { namespace }

    it_behaves_like 'assigns security policy project'
  end
end
