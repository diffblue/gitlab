# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Query'] do
  specify do
    foss_expected_fields = [
      :board_list,
      :ci_application_settings,
      :ci_config,
      :ci_variables,
      :container_repository,
      :current_user,
      :design_management,
      :echo,
      :gitpod_enabled,
      :group,
      :issue,
      :issues,
      :jobs,
      :merge_request,
      :metadata,
      :milestone,
      :namespace,
      :package,
      :project,
      :projects,
      :query_complexity,
      :runner,
      :runner_platforms,
      :runner_setup,
      :runners,
      :snippets,
      :timelogs,
      :todo,
      :topics,
      :usage_trends_measurements,
      :user,
      :users,
      :work_item
    ]

    ee_expected_fields = [
      :ci_minutes_usage,
      :current_license,
      :devops_adoption_enabled_namespaces,
      :epic_board_list,
      :geo_node,
      :instance_security_dashboard,
      :iteration,
      :license_history_entries,
      :subscription_future_entries,
      :vulnerabilities,
      :vulnerabilities_count_by_day,
      :vulnerability
    ]

    all_expected_fields = foss_expected_fields + ee_expected_fields

    expect(described_class).to have_graphql_fields(*all_expected_fields)
  end

  describe 'epicBoardList field' do
    subject { described_class.fields['epicBoardList'] }

    it 'finds an epic board list by its gid' do
      is_expected.to have_graphql_arguments(:id, :epic_filters)
      is_expected.to have_graphql_type(Types::Boards::EpicListType)
      is_expected.to have_graphql_resolver(Resolvers::Boards::EpicListResolver)
    end
  end
end
