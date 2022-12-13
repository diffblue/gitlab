# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a compliance frameworks list for a project', feature_category: :compliance_management do
  include GraphqlHelpers

  let_it_be(:project_member) { create(:project_member, :maintainer) }
  let_it_be(:project) { project_member.project }
  let_it_be(:current_user) { project_member.user }

  let_it_be(:query) do
    graphql_query_for(
      :project, { full_path: project.full_path }, 'complianceFrameworks { nodes { name } }'
    )
  end

  let(:compliance_frameworks) { graphql_data.dig('project', 'complianceFrameworks', 'nodes') }

  context 'when the project has no compliance framework assigned' do
    it 'is an empty array' do
      post_graphql(query, current_user: current_user)

      expect(compliance_frameworks).to be_empty
    end
  end

  context 'when the project has a compliance framework assigned' do
    before do
      project.update!(compliance_framework_setting: create(:compliance_framework_project_setting, :sox))
    end

    it 'includes its name' do
      post_graphql(query, current_user: current_user)

      expect(compliance_frameworks).to contain_exactly('name' => 'SOX')
    end
  end
end
