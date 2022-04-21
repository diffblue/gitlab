# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.vulnerabilities.sort' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, security_dashboard_projects: [project]) }
  let_it_be(:data_path) { %w[vulnerabilities] }

  before do
    project.add_developer(current_user)
    stub_licensed_features(security_dashboard: true)
  end

  def pagination_query(params)
    graphql_query_for(
      :vulnerabilities,
      params.merge({ projectId: project.id }),
      "#{page_info} nodes { id }"
    )
  end

  [true, false].each do |flag_enabled|
    context 'sort by state' do
      let_it_be(:vulnerability_confirmed1) { create(:vulnerability, :confirmed, project: project) }
      let_it_be(:vulnerability_confirmed2) { create(:vulnerability, :confirmed, project: project) }
      let_it_be(:vulnerability_detected1) { create(:vulnerability, :detected, project: project) }
      let_it_be(:vulnerability_dismissed1) { create(:vulnerability, :dismissed, project: project) }
      let_it_be(:vulnerability_resolved1) { create(:vulnerability, :resolved, project: project) }
      let_it_be(:vulnerability_detected2) { create(:vulnerability, :detected, project: project) }

      context "when the new_graphql_keyset_pagination FF state #{flag_enabled}" do
        before do
          stub_feature_flags(new_graphql_keyset_pagination: flag_enabled)
        end

        context 'sort by STATE_ASC' do
          it_behaves_like 'sorted paginated query' do
            let(:sort_param) { :state_asc }
            let(:first_param) { 2 }
            let(:all_records) do
              [
                vulnerability_detected1,
                vulnerability_detected2,
                vulnerability_confirmed1,
                vulnerability_confirmed2,
                vulnerability_resolved1,
                vulnerability_dismissed1
              ].map(&:to_gid).map(&:to_s)
            end
          end
        end

        context 'sort by STATE_ASC' do
          it_behaves_like 'sorted paginated query' do
            let(:sort_param) { :state_desc }
            let(:first_param) { 2 }
            let(:all_records) do
              [
                vulnerability_dismissed1,
                vulnerability_resolved1,
                vulnerability_confirmed2,
                vulnerability_confirmed1,
                vulnerability_detected2,
                vulnerability_detected1
              ].map(&:to_gid).map(&:to_s)
            end
          end
        end
      end
    end

    context 'sort by report type' do
      let_it_be(:vulnerability1) { create(:vulnerability, :secret_detection, project: project) }
      let_it_be(:vulnerability2) { create(:vulnerability, :sast, project: project) }
      let_it_be(:vulnerability3) { create(:vulnerability, :secret_detection, project: project) }
      let_it_be(:vulnerability4) { create(:vulnerability, :sast, project: project) }

      context "when the new_graphql_keyset_pagination FF state #{flag_enabled}" do
        before do
          stub_feature_flags(new_graphql_keyset_pagination: flag_enabled)
        end

        context 'sort by REPORT_TYPE_ASC' do
          it_behaves_like 'sorted paginated query' do
            let(:sort_param) { :report_type_asc }
            let(:first_param) { 2 }
            let(:all_records) do
              [
                vulnerability4,
                vulnerability2,
                vulnerability3,
                vulnerability1
              ].map(&:to_gid).map(&:to_s)
            end
          end
        end

        context 'sort by STATE_ASC' do
          it_behaves_like 'sorted paginated query' do
            let(:sort_param) { :report_type_desc }
            let(:first_param) { 2 }
            let(:all_records) do
              [
                vulnerability3,
                vulnerability1,
                vulnerability4,
                vulnerability2
              ].map(&:to_gid).map(&:to_s)
            end
          end
        end
      end
    end
  end
end
