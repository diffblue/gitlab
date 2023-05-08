# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Query'], feature_category: :shared do
  include_context 'with FOSS query type fields'

  specify do
    expected_ee_fields = [
      :ci_catalog_resources,
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
      :vulnerability,
      :instance_external_audit_event_destinations
    ]

    all_expected_fields = expected_foss_fields + expected_ee_fields

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
