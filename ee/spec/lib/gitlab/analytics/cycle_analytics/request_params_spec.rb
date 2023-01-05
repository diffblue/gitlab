# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::RequestParams do
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
  let(:params) do
    {
      created_after: '2019-01-01',
      created_before: '2019-03-01',
      project_ids: [2, 3],
      group: root_group,
      current_user: user
    }
  end

  subject { described_class.new(params) }

  before do
    root_group.add_owner(user)
  end

  describe 'validations' do
    it 'is valid' do
      expect(subject).to be_valid
    end

    context 'when `created_before` is missing' do
      before do
        params[:created_before] = nil
      end

      it 'is valid', time_travel_to: '2019-03-01' do
        expect(subject).to be_valid
      end
    end

    context 'when `created_before` is earlier than `created_after`' do
      before do
        params[:created_before] = '2015-01-01'
      end

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:created_before]).not_to be_empty
      end
    end

    context 'when the date range exceeds 180 days' do
      before do
        params[:created_before] = '2019-07-15'
      end

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:created_after]).to include(s_('CycleAnalytics|The given date range is larger than 180 days'))
      end
    end
  end

  it 'casts `created_after` to `Time`' do
    expect(subject.created_after).to be_a_kind_of(Time)
  end

  it 'casts `created_before` to `Time`' do
    expect(subject.created_before).to be_a_kind_of(Time)
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
          params[:group] = nil
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

  describe 'optional `group_id`' do
    context 'when `group_id` is not empty' do
      let(:group_id) { 'ca-test-group' }

      before do
        params[:group] = group_id
      end

      it { expect(subject.group).to eq(group_id) }
    end

    context 'when `group_id` is nil' do
      before do
        params[:group] = nil
      end

      it { expect(subject.group).to eq(nil) }
    end

    context 'when `group_id` is a subgroup' do
      before do
        params[:group] = sub_group.id
      end

      it { expect(subject.group).to eq(sub_group.id) }
    end
  end

  describe 'optional `value_stream`' do
    context 'when `value_stream` is not empty' do
      let(:value_stream) { instance_double('Analytics::CycleAnalytics::GroupValueStream') }

      before do
        params[:value_stream] = value_stream
      end

      it { expect(subject.value_stream).to eq(value_stream) }
    end

    context 'when `value_stream` is nil' do
      before do
        params[:value_stream] = nil
      end

      it { expect(subject.value_stream).to eq(nil) }
    end
  end

  describe 'issuable filter params' do
    let_it_be(:stage) { create(:cycle_analytics_group_stage, namespace: root_group) }

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

  describe 'sorting params' do
    before do
      params.merge!(sort: 'duration', direction: 'asc')
    end

    it 'converts sorting params to symbol when passing it to data collector' do
      data_collector_params = subject.to_data_collector_params

      expect(data_collector_params[:sort]).to eq(:duration)
      expect(data_collector_params[:direction]).to eq(:asc)
    end

    it 'adds sorting params to data attributes' do
      data_attributes = subject.to_data_attributes

      expect(data_attributes[:sort]).to eq('duration')
      expect(data_attributes[:direction]).to eq('asc')
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

  describe 'use_aggregated_data_collector param' do
    subject(:value) { described_class.new(params).to_data_collector_params[:use_aggregated_data_collector] }

    it { is_expected.to eq(true) }

    context 'when the aggregation is disabled by the user' do
      before do
        aggregation = ::Analytics::CycleAnalytics::Aggregation.safe_create_for_namespace(root_group)
        aggregation.update!(enabled: false)
      end

      it { is_expected.to eq(false) }
    end
  end
end
