# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creates and assigns scan execution policy project to a project/namespace', feature_category: :security_policy_management do
  include GraphqlHelpers

  let_it_be_with_refind(:owner) { create(:user) }
  let_it_be_with_refind(:maintainer) { create(:user) }
  let_it_be_with_refind(:project) { create(:project, namespace: owner.namespace) }
  let_it_be_with_refind(:namespace) { create(:group) }

  let(:current_user) { owner }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation
    variables = { full_path: container.full_path }

    graphql_mutation(:security_policy_project_create, variables) do
      <<-QL.strip_heredoc
        project {
          id
          name
        }
        errors
      QL
    end
  end

  def mutation_response
    graphql_mutation_response(:security_policy_project_create)
  end

  shared_examples 'creates security policy project' do
    context 'when licensed feature is available' do
      before do
        # TODO: investigate too many qeuries issue as part of Project Management Database and Query Performance
        # Epic: https://gitlab.com/groups/gitlab-org/-/epics/5804
        # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/348344
        allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(140)
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when user is an owner of the container' do
        it 'creates and assigns the security policy project', :aggregate_failures do
          expect { subject }.to change { ::Project.count }.by(1)

          orchestration_policy_configuration = container.security_orchestration_policy_configuration

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['errors']).to be_empty
          expect(mutation_response.dig('project', 'id')).to eq(orchestration_policy_configuration.security_policy_management_project.to_gid.to_s)
          expect(mutation_response.dig('project', 'name')).to eq("#{container.name} - Security policy project")
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

    it_behaves_like 'creates security policy project'
  end

  context 'for namespace' do
    let(:container) { namespace }

    before do
      namespace.add_owner(owner)
    end

    it_behaves_like 'creates security policy project'
  end
end
