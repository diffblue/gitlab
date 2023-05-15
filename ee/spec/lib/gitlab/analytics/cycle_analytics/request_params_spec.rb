# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::RequestParams, feature_category: :value_stream_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:root_group) { create(:group) }
  let_it_be(:sub_group) { create(:group, parent: root_group) }
  let_it_be(:sub_group_project) { create(:project, id: 1, group: sub_group) }
  let_it_be(:root_group_projects) do
    [
      create(:project, id: 2, group: root_group),
      create(:project, id: 3, group: root_group)
    ]
  end

  let(:project_ids) { root_group_projects.collect(&:id) }
  let(:namespace) { root_group }

  subject { described_class.new(params) }

  before do
    root_group.add_owner(user)
  end

  it_behaves_like 'unlicensed cycle analytics request params'

  context 'when Namespaces::ProjectNamespace is given' do
    it_behaves_like 'unlicensed cycle analytics request params' do
      let(:namespace) { sub_group_project.reload.project_namespace }
    end
  end

  context 'when licensed' do
    let(:params) do
      {
        created_after: '2019-01-01',
        created_before: '2019-03-01',
        project_ids: [2, 3],
        namespace: namespace,
        current_user: user
      }
    end

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)
    end

    it 'is valid' do
      expect(subject).to be_valid
    end

    describe 'optional `project_ids`' do
      context 'when `project_ids` is not empty' do
        def json_project(project)
          { id: project.to_gid.to_s,
            name: project.name,
            path_with_namespace: project.path_with_namespace,
            avatar_url: project.avatar_url }.to_json
        end

        context 'with a valid group' do
          it { expect(subject.project_ids).to eq(project_ids) }

          it 'contains every project of the group' do
            root_group_projects.each do |project|
              expect(subject.to_data_attributes[:projects]).to include(json_project(project))
            end
          end
        end

        context 'without a valid group' do
          before do
            params[:namespace] = nil
          end

          it { expect(subject.to_data_attributes[:projects]).to eq(nil) }
        end
      end

      context 'when `project_ids` is not an array' do
        before do
          params[:project_ids] = 1
        end

        it { expect(subject.project_ids).to eq([1]) }
      end

      context 'when `project_ids` is nil' do
        before do
          params[:project_ids] = nil
        end

        it { expect(subject.project_ids).to eq([]) }
      end

      context 'when `project_ids` is empty' do
        before do
          params[:project_ids] = []
        end

        it { expect(subject.project_ids).to eq([]) }
      end

      context 'is a subgroup project' do
        before do
          params[:project_ids] = sub_group_project.id
        end

        it { expect(subject.project_ids).to eq([sub_group_project.id]) }
      end
    end

    describe 'issuable filter params' do
      let_it_be(:stage) { create(:cycle_analytics_stage, namespace: root_group) }

      before do
        params.merge!(
          milestone_title: 'title',
          assignee_username: ['username1'],
          label_name: %w[label1 label2],
          author_username: 'author',
          stage_id: stage.id,
          value_stream: stage.value_stream
        )
      end

      subject { described_class.new(params).to_data_attributes }

      it "has the correct attributes" do
        expect(subject[:milestone]).to eq('title')
        expect(subject[:assignees]).to eq('["username1"]')
        expect(subject[:labels]).to eq('["label1","label2"]')
        expect(subject[:author]).to eq('author')
        expect(subject[:stage]).to eq(%Q|{"id":#{stage.id},"title":"#{stage.name}"}|)
      end
    end

    describe 'group-level data attributes' do
      subject(:attributes) { described_class.new(params).to_data_attributes }

      it 'includes the namespace attribute' do
        expect(attributes).to match(hash_including({
          namespace: {
            name: root_group.name,
            full_path: "groups/#{root_group.full_path}",
            type: "Group"
          }
        }))
      end
    end

    describe 'aggregation params' do
      it 'exposes the aggregation params' do
        data_collector_params = subject.to_data_attributes

        expect(data_collector_params[:aggregation]).to eq({
          enabled: 'true',
          last_run_at: nil,
          next_run_at: nil
        })
      end
    end

    describe 'feature availablity data attributes' do
      subject(:value) { described_class.new(params).to_data_attributes }

      it 'enables all paid features' do
        is_expected.to match(a_hash_including(enable_tasks_by_type_chart: 'true',
          enable_customizable_stages: 'true',
          enable_projects_filter: 'true'))
      end

      context 'when Namespaces::ProjectNamespace is given' do
        before do
          stub_licensed_features(cycle_analytics_for_projects: true)

          # The reload is needed because the project association with inverse_of is not loaded properly
          params[:namespace] = sub_group_project.project_namespace.reload
        end

        it 'disables the task by type chart and the projects filter' do
          is_expected.to match(a_hash_including(enable_tasks_by_type_chart: 'false',
            enable_customizable_stages: 'true',
            enable_projects_filter: 'false'))
        end

        describe 'use_aggregated_data_collector param' do
          subject(:value) { described_class.new(params).to_data_collector_params[:use_aggregated_data_collector] }

          it { is_expected.to eq(true) }
        end
      end
    end
  end
end
