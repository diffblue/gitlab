# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['InstanceSecurityDashboard'] do
  let_it_be(:project) { create(:project) }
  let(:result) { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }
  let_it_be(:other_project) { create(:project) }
  let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }

  let(:fields) do
    %i[projects vulnerability_scanners vulnerability_severities_count vulnerability_grades cluster_agents]
  end

  before do
    project.add_developer(user)
    other_project.add_developer(user)

    stub_licensed_features(security_dashboard: true)
  end

  specify { expect(described_class).to have_graphql_fields(fields) }

  describe 'projects' do
    let(:query) do
      %(
        query {
          instanceSecurityDashboard {
            projects {
              nodes {
                id
              }
            }
          }
        }
      )
    end

    subject(:projects) { result.dig('data', 'instanceSecurityDashboard', 'projects') }

    context 'when user is not logged in' do
      let(:current_user) { nil }

      it { is_expected.to be_nil }
    end

    context 'when user is logged in' do
      let(:current_user) { user }

      it 'is a list of projects configured for instance security dashboard' do
        project_ids = projects['nodes'].pluck('id')

        expect(project_ids).to eq [GitlabSchema.id_from_object(project).to_s]
      end
    end
  end
end
