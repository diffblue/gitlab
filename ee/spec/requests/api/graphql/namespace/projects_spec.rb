# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Namespace.projects', feature_category: :projects do
  include GraphqlHelpers

  describe 'sorting and pagination' do
    let_it_be(:ns) { create(:group) }
    let_it_be(:current_user) { create(:user) }

    let!(:project_1) { create(:project, namespace: ns, name: 'Project', path: 'project') }
    let!(:project_2) { create(:project, namespace: ns, name: 'Test Project', path: 'test-project') }
    let!(:project_3) { create(:project, namespace: ns, name: 'Test', path: 'test') }
    let!(:project_4) { create(:project, namespace: ns, name: 'Test Project Other', path: 'other-test-project') }

    let(:data_path) { [:namespace, :projects] }

    let(:ns_args) { graphql_args(full_path: ns.full_path) }
    let(:project_args) { graphql_args(include_subgroups: true, search: 'test') }

    before do
      ns.add_owner(current_user)
    end

    def pagination_query(params)
      graphql_query_for(:namespace, ns_args,
        query_nodes(:projects, :name, include_pagination_info: true, args: params + project_args))
    end

    context 'when sorting by STORAGE' do
      before do
        project_4.statistics.update!(lfs_objects_size: 1, repository_size: 4.gigabytes)
        project_2.statistics.update!(lfs_objects_size: 1, repository_size: 2.gigabytes)
        project_3.statistics.update!(lfs_objects_size: 2, repository_size: 1.gigabytes)
      end

      it_behaves_like 'sorted paginated query' do
        let(:node_path) { %w[name] }
        let(:sort_param) { :STORAGE }
        let(:first_param) { 2 }
        let(:all_records) { [project_4, project_2, project_3].map(&:name) }
      end
    end
  end
end
