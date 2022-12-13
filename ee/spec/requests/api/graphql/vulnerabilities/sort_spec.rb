# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.vulnerabilities.sort', feature_category: :vulnerability_management do
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
    context 'sort by severity' do
      let_it_be(:vuln_critical1) { create(:vulnerability, :critical_severity, :with_read, project: project) }
      let_it_be(:vuln_critical2) { create(:vulnerability, :critical_severity, :with_read, project: project) }
      let_it_be(:vuln_high1) { create(:vulnerability, :high_severity, :with_read, project: project) }
      let_it_be(:vuln_high2) { create(:vulnerability, :high_severity, :with_read, project: project) }
      let_it_be(:vuln_medium1) { create(:vulnerability, :medium_severity, :with_read, project: project) }
      let_it_be(:vuln_medium2) { create(:vulnerability, :medium_severity, :with_read, project: project) }
      let_it_be(:vuln_low1) { create(:vulnerability, :low_severity, :with_read, project: project) }
      let_it_be(:vuln_low2) { create(:vulnerability, :low_severity, :with_read, project: project) }

      context 'sort by SEVERITY_ASC' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :severity_asc }
          let(:first_param) { 2 }
          let(:all_records) do
            [
              vuln_low2,
              vuln_low1,
              vuln_medium2,
              vuln_medium1,
              vuln_high2,
              vuln_high1,
              vuln_critical2,
              vuln_critical1
            ].map(&:to_gid).map(&:to_s)
          end
        end
      end

      context 'sort by SEVERITY_DESC' do
        it_behaves_like 'sorted paginated query' do
          let(:sort_param) { :severity_desc }
          let(:first_param) { 2 }
          let(:all_records) do
            [
              vuln_critical2,
              vuln_critical1,
              vuln_high2,
              vuln_high1,
              vuln_medium2,
              vuln_medium1,
              vuln_low2,
              vuln_low1
            ].map(&:to_gid).map(&:to_s)
          end
        end
      end
    end
  end
end
