# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.group(fullPath).projects', feature_category: :compliance_management do
  include GraphqlHelpers

  let(:query) do
    graphql_query_for(
      :group, { full_path: namespace.full_path },
      %( name #{query_nodes(:projects, :full_path, args: params)} )
    )
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }

  let_it_be(:project_with_framework_1) { create(:project, group: namespace) }
  let_it_be(:project_with_framework_2) { create(:project, group: namespace) }
  let_it_be(:project_without_framework) { create(:project, group: namespace) }

  let_it_be(:compliance_framework_1) { create(:compliance_framework, namespace: namespace, name: 'Test1') }
  let_it_be(:compliance_framework_2) { create(:compliance_framework, namespace: namespace, name: 'Test2') }

  let_it_be(:compliance_framework_1_setting) do
    create(:compliance_framework_project_setting, project: project_with_framework_1,
      compliance_management_framework: compliance_framework_1)
  end

  let_it_be(:compliance_framework_2_setting) do
    create(:compliance_framework_project_setting, project: project_with_framework_2,
      compliance_management_framework: compliance_framework_2)
  end

  before do
    namespace.add_owner(user)
  end

  subject(:execute_query) { post_graphql(query, current_user: user) }

  def projects_full_paths
    execute_query

    graphql_data_at(:group, :projects, :nodes, :full_path)
  end

  context 'when compliance framework id filter is passed' do
    let(:params) do
      { compliance_framework_filters: { id: compliance_framework_1.to_gid.to_s } }
    end

    it "returns project matching id" do
      expect(projects_full_paths).to eq([project_with_framework_1.full_path])
    end
  end

  context 'when compliance framework not id filter is passed' do
    let(:params) do
      { compliance_framework_filters: { not: { id: compliance_framework_1.to_gid.to_s } } }
    end

    it 'returns project where id is not passed id' do
      expect(projects_full_paths).to contain_exactly(project_with_framework_2.full_path,
        project_without_framework.full_path)
    end
  end

  context 'when both compliance framework id and not id filter are passed' do
    context 'when id and not id are same' do
      let(:params) do
        {
          compliance_framework_filters: {
            id: compliance_framework_1.to_gid.to_s,
            not: { id: compliance_framework_1.to_gid.to_s }
          }
        }
      end

      it 'returns no project' do
        expect(projects_full_paths).to be_empty
      end
    end

    context 'when id and not id are different' do
      let(:params) do
        {
          compliance_framework_filters: {
            id: compliance_framework_1.to_gid.to_s,
            not: { id: compliance_framework_2.to_gid.to_s }
          }
        }
      end

      it 'returns project with correct id' do
        expect(projects_full_paths).to contain_exactly(project_with_framework_1.full_path)
      end
    end
  end

  context 'when compliance framework presence filter is passed as ANY' do
    let(:params) do
      {
        compliance_framework_filters: {
          presence_filter: :ANY
        }
      }
    end

    it 'returns projects with any framework attached' do
      expect(projects_full_paths).to contain_exactly(project_with_framework_1.full_path,
        project_with_framework_2.full_path)
    end
  end

  context 'when compliance framework presence filter is passed as NONE' do
    let(:params) do
      {
        compliance_framework_filters: {
          presence_filter: :NONE
        }
      }
    end

    it 'returns project without any framework' do
      expect(projects_full_paths).to contain_exactly(project_without_framework.full_path)
    end
  end
end
