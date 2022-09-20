# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::TypeOfWork::TasksByType do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:other_group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:label) { create(:group_label, group: group) }
  let_it_be(:other_label) { create(:group_label, group: group) }
  let_it_be(:not_used_label) { create(:group_label, group: group) }
  let_it_be(:label_for_subgroup) { create(:group_label, group: group) }
  let_it_be(:other_label) { create(:group_label, group: other_group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:assignee) { create(:user) }
  let_it_be(:milestone) { create(:milestone, group: group) }

  let(:params) do
    {
      group: group,
      current_user: user,
      params: {
        label_names: [label.name, label_for_subgroup.name],
        created_after: 10.days.ago,
        created_before: Date.today
      }
    }
  end

  subject do
    described_class.new(**params).counts_by_labels
  end

  around do |example|
    freeze_time { example.run }
  end

  before do
    group.add_reporter(user)
    group.add_developer(assignee)
  end

  shared_examples '#counts_by_labels' do
    let!(:with_label) do
      create(factory_name, {
        :created_at => 3.days.ago,
        :labels => [label],
        :assignees => [assignee],
        :milestone => milestone,
        project_attribute_name => project
      })
    end

    let!(:with_label_on_other_date) do
      create(factory_name, {
        :created_at => 2.days.ago,
        :labels => [label],
        project_attribute_name => create(:project, group: group)
      })
    end

    let!(:with_subgroup) do
      create(factory_name, {
        :created_at => 3.days.ago,
        :labels => [label, label_for_subgroup],
        project_attribute_name => create(:project, group: subgroup)
      })
    end

    let!(:outside_group) do
      create(factory_name, {
        :created_at => 3.days.ago,
        :labels => [other_label],
        project_attribute_name => create(:project, group: other_group)
      })
    end

    def label_count_for(label, result)
      label_count_result = result.find { |r| r.label.id == label.id }
      label_count_result.series.sum(&:last) # format: [DATE, COUNT]
    end

    it 'counts the records by label and date' do
      expect(label_count_for(label, subject)).to eq(3)
    end

    it 'counts should include subgroups' do
      expect(label_count_for(label_for_subgroup, subject)).to eq(1)
    end

    it 'does not include count from outside of the group' do
      label_names = subject.map { |r| r.label.name }

      expect(label_names).to contain_exactly(label.name, label_for_subgroup.name)
    end

    context 'when group without any record is given' do
      before do
        params[:group] = create(:group)
      end

      it { expect(subject).to be_empty }
    end

    context 'when no labels are given' do
      before do
        params[:params][:label_names] = []
      end

      it { expect(subject).to be_empty }
    end

    context 'when records are outside of the given time range' do
      before do
        params[:params][:created_after] = 2.years.ago
        params[:params][:created_before] = 1.year.ago
      end

      it { expect(subject).to be_empty }
    end

    context 'when filtering by `project_ids`' do
      before do
        params[:params][:project_ids] = [project.id]
      end

      it { expect(label_count_for(label, subject)).to eq(1) }
    end

    context 'when filtering by `author_username`' do
      before do
        params[:params][:author_username] = with_label.author.username
      end

      it { expect(label_count_for(label, subject)).to eq(1) }
    end

    context 'when filtering by `assignee_username`' do
      before do
        params[:params][:assignee_username] = [assignee.username]
      end

      it { expect(label_count_for(label, subject)).to eq(1) }
    end

    context 'when filtering by `milestone_title`' do
      before do
        params[:params][:milestone_title] = milestone.title
      end

      it { expect(label_count_for(label, subject)).to eq(1) }
    end
  end

  shared_examples '#top_labels' do
    let(:top_labels) { described_class.new(**params).top_labels }

    let!(:with_label) do
      create(factory_name, {
        :created_at => 3.days.ago,
        :labels => [label, other_label],
        project_attribute_name => project
      })
    end

    let!(:with_other_label_only) do
      create(factory_name, {
        :created_at => 3.days.ago,
        :labels => [other_label],
        project_attribute_name => create(:project, group: group)
      })
    end

    it 'sorts by descending order' do
      expect(top_labels).to eq([other_label, label])
    end

    it 'limits the the size of the results' do
      expect(described_class.new(**params).top_labels(1)).to eq([other_label])
    end
  end

  context 'when subject is `Issue`' do
    let(:factory_name) { :labeled_issue }
    let(:project_attribute_name) { :project }

    before do
      params[:params][:subject] = Issue.to_s
    end

    it_behaves_like '#counts_by_labels'
    it_behaves_like '#top_labels'
  end

  context 'when subject is `MergeRequest`' do
    let(:factory_name) { :labeled_merge_request }
    let(:project_attribute_name) { :source_project }

    before do
      params[:params][:subject] = MergeRequest.to_s
    end

    it_behaves_like '#counts_by_labels'
    it_behaves_like '#top_labels'
  end

  context 'when unknown `subject` is given' do
    before do
      params[:params][:subject] = 'invalid'

      create(:merge_request, {
        created_at: 3.days.ago,
        labels: [label],
        source_project: project
      })
    end

    it 'falls back to `MergeRequestFinder`' do
      expect(subject.map(&:label)).to eq([label])
    end
  end
end
