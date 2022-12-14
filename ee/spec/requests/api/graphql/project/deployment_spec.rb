# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Deployment query', feature_category: :continuous_delivery do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, :repository, group: group) }
  let_it_be(:maintainer) { create(:user).tap { |u| project.add_maintainer(u) } }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:guest) { create(:user).tap { |u| project.add_guest(u) } }
  let_it_be(:qa_group) { create(:group, name: 'QA', parent: group) }
  let_it_be(:qa_user) { create(:user).tap { |u| qa_group.add_maintainer(u) } }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:deployment) { create(:deployment, environment: environment, project: project) }

  let(:user) { developer }

  subject { post_graphql(query, current_user: user) }

  context 'with approval rules' do
    let!(:protected_environment) do
      create(:protected_environment,
        name: environment.name,
        project: project,
        approval_rules: [qa_approval_rule, maintainer_approval_rule])
    end

    let(:qa_approval_rule) do
      build(:protected_environment_approval_rule, group: qa_group, required_approvals: 1)
    end

    let(:maintainer_approval_rule) do
      build(:protected_environment_approval_rule, :maintainer_access, required_approvals: 1)
    end

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            deployment(iid: #{deployment.iid}) {
              approvalSummary {
                totalRequiredApprovals
                totalPendingApprovalCount
                status
                rules {
                  group {
                    name
                  }
                  user {
                    name
                  }
                  accessLevel {
                    stringValue
                  }
                  approvedCount
                  requiredApprovals
                  pendingApprovalCount
                  status
                  approvals {
                    user {
                      name
                    }
                    status
                    comment
                    createdAt
                    updatedAt
                  }
                }
              }
            }
          }
        }
      )
    end

    it 'returns the summary of the deployment approval', :aggregate_failures do
      subject

      summary_data = graphql_data_at(:project, :deployment, :approvalSummary)

      expect(summary_data['totalRequiredApprovals']).to eq(2)
      expect(summary_data['totalPendingApprovalCount']).to eq(2)
      expect(summary_data['status']).to eq('PENDING_APPROVAL')
      expect(summary_data['rules'].count).to eq(2)

      qa_rule = summary_data['rules'].find { |r| r.dig('group', 'name') == 'QA' }

      expect(qa_rule['requiredApprovals']).to eq(1)
      expect(qa_rule['pendingApprovalCount']).to eq(1)
      expect(qa_rule['approvals']).to be_empty

      maintainer_rule = summary_data['rules'].find { |r| r.dig('accessLevel', 'stringValue') == 'MAINTAINER' }

      expect(maintainer_rule['requiredApprovals']).to eq(1)
      expect(maintainer_rule['pendingApprovalCount']).to eq(1)
      expect(maintainer_rule['approvals']).to be_empty
    end

    context 'when QA user approves the deployment' do
      let!(:approval) do
        create(:deployment_approval, deployment: deployment, user: qa_user, approval_rule: qa_approval_rule)
      end

      it 'reflects the approval', :aggregate_failures do
        subject

        summary_data = graphql_data_at(:project, :deployment, :approvalSummary)

        expect(summary_data['totalPendingApprovalCount']).to eq(1)
        expect(summary_data['status']).to eq('PENDING_APPROVAL')

        qa_rule = summary_data['rules'].find { |r| r.dig('group', 'name') == 'QA' }

        expect(qa_rule['pendingApprovalCount']).to eq(0)
        expect(qa_rule['approvals'].count).to eq(1)
        expect(qa_rule['approvals'].first['user']['name']).to eq(qa_user.name)
        expect(qa_rule['approvals'].first['comment']).to eq(approval.comment)
        expect(qa_rule['approvals'].first['status']).to eq('APPROVED')

        maintainer_rule = summary_data['rules'].find { |r| r.dig('accessLevel', 'stringValue') == 'MAINTAINER' }

        expect(maintainer_rule['pendingApprovalCount']).to eq(1)
        expect(maintainer_rule['approvals']).to be_empty
      end
    end

    context 'when a maintainer approves the deployment' do
      let!(:approval) do
        create(:deployment_approval, deployment: deployment, user: maintainer, approval_rule: maintainer_approval_rule)
      end

      it 'reflects the approval', :aggregate_failures do
        subject

        summary_data = graphql_data_at(:project, :deployment, :approvalSummary)

        expect(summary_data['totalPendingApprovalCount']).to eq(1)
        expect(summary_data['status']).to eq('PENDING_APPROVAL')

        qa_rule = summary_data['rules'].find { |r| r.dig('group', 'name') == 'QA' }

        expect(qa_rule['pendingApprovalCount']).to eq(1)
        expect(qa_rule['approvals']).to be_empty

        maintainer_rule = summary_data['rules'].find { |r| r.dig('accessLevel', 'stringValue') == 'MAINTAINER' }

        expect(maintainer_rule['pendingApprovalCount']).to eq(0)
        expect(maintainer_rule['approvals'].count).to eq(1)
        expect(maintainer_rule['approvals'].first['user']['name']).to eq(maintainer.name)
        expect(maintainer_rule['approvals'].first['comment']).to eq(approval.comment)
        expect(maintainer_rule['approvals'].first['status']).to eq('APPROVED')
      end
    end

    context 'when all rules are approved' do
      before do
        create(:deployment_approval, deployment: deployment, user: qa_user, approval_rule: qa_approval_rule)
        create(:deployment_approval, deployment: deployment, user: maintainer, approval_rule: maintainer_approval_rule)
      end

      it 'returns the approved status', :aggregate_failures do
        subject

        summary_data = graphql_data_at(:project, :deployment, :approvalSummary)

        expect(summary_data['totalPendingApprovalCount']).to eq(0)
        expect(summary_data['status']).to eq('APPROVED')
      end
    end

    context 'when one of rules is rejected' do
      before do
        create(:deployment_approval, :rejected, deployment: deployment, user: qa_user, approval_rule: qa_approval_rule)
      end

      it 'returns the rejected status', :aggregate_failures do
        subject

        summary_data = graphql_data_at(:project, :deployment, :approvalSummary)

        expect(summary_data['totalPendingApprovalCount']).to eq(2)
        expect(summary_data['status']).to eq('REJECTED')
      end
    end

    context 'when requesting user permissions' do
      let(:query) do
        %(
          query {
            project(fullPath: "#{project.full_path}") {
              deployment(iid: #{deployment.iid}) {
                userPermissions {
                  approveDeployment
                }
              }
            }
          }
        )
      end

      it 'returns user permissions of the deployments', :aggregate_failures do
        subject

        permissions = graphql_data_at(:project, :deployment, :userPermissions)

        expect(permissions['approveDeployment']).to eq(Ability.allowed?(user, :approve_deployment, deployment))
      end
    end

    context 'when guest user executes the GraphQL query' do
      let(:user) { guest }

      it 'returns nothing' do
        subject

        summary_data = graphql_data_at(:project, :deployment, :approvalSummary)

        expect(summary_data).to be_nil
      end
    end
  end
end
