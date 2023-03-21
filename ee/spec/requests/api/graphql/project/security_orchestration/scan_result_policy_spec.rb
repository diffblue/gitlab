# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).scanResultPolicies', feature_category: :security_policy_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:policy_management_project) { create(:project, :repository) }
  let_it_be(:user) { policy_management_project.first_owner }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:action) do
    {
      type: 'require_approval',
      approvals_required: 1,
      user_approvers_ids: [user.id],
      group_approvers_ids: [group.id],
      role_approvers: %w[maintainer developer]
    }
  end

  let_it_be(:policy) { build(:scan_result_policy, actions: [action]) }
  let_it_be(:policy_yaml) { build(:orchestration_policy_yaml, scan_result_policy: [policy]) }
  let_it_be(:policy_configuration) do
    create(:security_orchestration_policy_configuration,
      security_policy_management_project: policy_management_project,
      project: project)
  end

  let_it_be(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          scanResultPolicies {
            nodes{
              userApprovers{
                id
                webUrl
              }
              groupApprovers{
                id
                webUrl
              }
              roleApprovers
            }
          }
        }
      }
    )
  end

  let_it_be(:expected_data) do
    [
      {
        "userApprovers" => [
          {
            "id" => "gid://gitlab/User/#{user.id}",
            "webUrl" => "http://localhost/#{user.full_path}"
          }
        ],
        "groupApprovers" => [
          {
            "id" => "gid://gitlab/Group/#{group.id}",
            "webUrl" => "http://localhost/groups/#{group.full_path}"
          }
        ],
        "roleApprovers" => %w[
          MAINTAINER
          DEVELOPER
        ]
      }
    ]
  end

  before do
    stub_licensed_features(security_orchestration_policies: true)
    project.add_maintainer(user)
    project.invited_groups = [group]
    allow_next_instance_of(Repository) do |repository|
      allow(repository).to receive(:blob_data_at).and_return(policy_yaml)
    end
  end

  subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

  it "returns both user and group approvers" do
    result = subject.dig('data', 'project', 'scanResultPolicies', 'nodes')

    expect(result).to eq(expected_data)
  end
end
