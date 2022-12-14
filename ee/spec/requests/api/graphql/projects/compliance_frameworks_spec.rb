# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting compliance frameworks for a collection of projects', feature_category: :compliance_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project_members) { create_list(:project_member, 2, :maintainer, user: current_user) }
  let_it_be(:project_ids) { project_members.map { |p| global_id_of(p.source) } }

  let(:query) do
    graphql_query_for(
      :projects, { ids: project_ids }, "nodes { #{query_nodes(:compliance_frameworks)} }"
    )
  end

  before_all do
    project_members.map(&:project).each do |project|
      project.compliance_framework_setting = create(:compliance_framework_project_setting)
    end
  end

  context 'querying a single project' do
    let(:single_project_query) do
      graphql_query_for(
        :projects, { ids: [project_ids.first] }, "nodes { #{query_nodes(:compliance_frameworks)} }"
      )
    end

    it 'avoids N+1 queries', :use_sql_query_cache do
      query_count = ActiveRecord::QueryRecorder.new(skip_cached: false) { post_graphql(query, current_user: current_user) }.count

      expect { post_graphql(single_project_query, current_user: current_user) }.not_to exceed_all_query_limit(query_count)
    end

    it 'contains the expected compliance framework' do
      post_graphql(single_project_query, current_user: current_user)

      expect(graphql_data_at(:projects, :nodes, 0, :complianceFrameworks, :nodes, 0, :name)).to eq 'GDPR'
    end
  end

  context 'projects can have a compliance framework' do
    let_it_be(:compliance_projects) { create_list(:project, 2, :with_compliance_framework) }
    let_it_be(:non_compliance_project) { create(:project) }

    let(:projects) { compliance_projects + [non_compliance_project] }
    let(:project_ids) { projects.map { |p| global_id_of(p) } }

    let(:query) do
      graphql_query_for(
        :projects, { ids: project_ids }, "nodes { #{query_nodes(:compliance_frameworks)} }"
      )
    end

    before do
      projects.each { |p| create(:project_member, :maintainer, source: p, user: current_user) }
      post_graphql(query, current_user: current_user)
    end

    subject { graphql_data_at(:projects, :nodes).map { |p| p.dig('complianceFrameworks', 'nodes') } }

    it 'contains the correct number of compliance frameworks' do
      expect(subject[0].size).to eq 0
      expect(subject[1].size).to eq 1
      expect(subject[2].size).to eq 1
    end
  end

  context 'projects that share the same compliance framework' do
    let_it_be(:framework) { create(:compliance_framework) }
    let_it_be(:project_1) { create(:project, compliance_framework_setting: create(:compliance_framework_project_setting, compliance_management_framework: framework )) }
    let_it_be(:project_2) { create(:project, compliance_framework_setting: create(:compliance_framework_project_setting, compliance_management_framework: framework )) }

    let(:projects) { [project_1, project_2] }
    let(:project_ids) { projects.map { |p| global_id_of(p) } }
    let(:query) do
      graphql_query_for(
        :projects, { ids: project_ids }, "nodes { #{query_nodes(:compliance_frameworks)} }"
      )
    end

    before do
      projects.each { |p| create(:project_member, :maintainer, source: p, user: current_user) }
      post_graphql(query, current_user: current_user)
    end

    subject { graphql_data_at(:projects, :nodes).map { |p| p.dig('complianceFrameworks', 'nodes', 0, 'id') } }

    it 'shares the same compliance framework id' do
      expect(subject[0]).to eq(subject[1])
    end
  end
end
