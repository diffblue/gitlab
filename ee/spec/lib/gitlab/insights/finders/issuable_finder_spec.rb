# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Finders::IssuableFinder, feature_category: :team_planning do
  using RSpec::Parameterized::TableSyntax

  around do |example|
    travel_to(Time.utc(2019, 3, 5)) { example.run }
  end

  let(:base_query) do
    {
      state: 'opened',
      group_by: 'months'
    }
  end

  let(:merge_request_extra_attrs) do
    [
      { source_branch: "add_images_and_changes" },
      { source_branch: "improve/awesome" },
      { source_branch: "feature_conflict" },
      { source_branch: "markdown" },
      { source_branch: "feature_one" },
      { source_branch: "feature_two" }
    ]
  end

  describe '#issuable_type' do
    subject { described_class.new(build(:project), nil, query: { issuable_type: issuable_type_in_query }).issuable_type }

    where(:issuable_type_in_query, :expected_issuable_type) do
      'issue' | :issue
      'issues' | :issue
      'merge_request' | :merge_request
      'merge_requests' | :merge_request
    end

    with_them do
      it { is_expected.to eq(expected_issuable_type) }
    end
  end

  describe '#issuable_state' do
    subject { described_class.new(build(:project), nil, query: { issuable_state: issuable_state_in_query }).issuable_state }

    where(:issuable_state_in_query, :expected_issuable_state) do
      nil | :opened
      'opened' | :opened
      'closed' | :closed
      'merged' | :merged
      'locked' | :locked
    end

    with_them do
      it { is_expected.to eq(expected_issuable_state) }
    end
  end

  describe '#period_field' do
    subject { described_class.new(build(:project), nil, query: { issuable_type: issuable_type_in_query, issuable_state: issuable_state_in_query }).period_field }

    where(:issuable_type_in_query, :issuable_state_in_query, :expected_period_field) do
      'issue' | nil | :created_at
      'merge_request' | nil | :created_at
      'issue' | 'opened' | :created_at
      'merge_request' | 'opened' | :created_at
      'issue' | 'closed' | :closed_at
      'merge_request' | 'closed' | :created_at
      'issue' | 'merged' | :created_at
      'merge_request' | 'merged' | :merged_at
      'issue' | 'locked' | :created_at
      'merge_request' | 'locked' | :created_at
    end

    with_them do
      it { is_expected.to eq(expected_period_field) }
    end
  end

  describe '#find' do
    def find(entity, query:, projects: {})
      described_class.new(entity, nil, query: query, projects: projects).find
    end

    it 'raises an error for an invalid :issuable_type option' do
      expect do
        find(build(:project), query: { issuable_type: 'foo' })
      end.to raise_error(described_class::InvalidIssuableTypeError, "Invalid `:issuable_type` option: `foo`. Allowed values are #{described_class::FINDERS.keys}!")
    end

    it 'raises an error for an invalid entity object' do
      expect do
        find(build(:user), query: { issuable_type: 'issue' })
      end.to raise_error(described_class::InvalidEntityError, 'Entity class `User` is not supported. Supported classes are Project and Namespace!')
    end

    it 'raises an error for an invalid :group_by option' do
      expect do
        find(build(:project), query: { issuable_type: 'issue', group_by: 'foo' })
      end.to raise_error(described_class::InvalidGroupByError, "Invalid `:group_by` option: `foo`. Allowed values are #{described_class::PERIODS.keys}!")
    end

    it 'defaults to the "days" period if no :group_by is given' do
      expect(described_class.new(build(:project), nil, query: { issuable_type: 'issue' }).__send__(:period)).to eq(:days)
    end

    it 'raises an error for an invalid :period_limit option' do
      expect do
        find(build(:project), query: { issuable_type: 'issue', group_by: 'months', period_limit: 'many' })
      end.to raise_error(described_class::InvalidPeriodLimitError, "Invalid `:period_limit` option: `many`. Expected an integer!")
    end

    shared_examples_for "insights issuable finder" do
      let(:label_bug) { create(label_type, label_entity_association_key => entity, name: 'Bug') }
      let(:label_manage) { create(label_type, label_entity_association_key => entity, name: 'Manage') }
      let(:label_plan) { create(label_type, label_entity_association_key => entity, name: 'Plan') }
      let(:label_create) { create(label_type, label_entity_association_key => entity, name: 'Create') }
      let(:label_quality) { create(label_type, label_entity_association_key => entity, name: 'Quality') }
      let(:extra_issuable_attrs) { [{}, {}, {}, {}, {}, {}] }
      let(:issuable_state) { :opened }
      let!(:issuable0) { create(:"labeled_#{issuable_type.singularize}", issuable_state, created_at: Time.utc(2018, 1, 1), project_association_key => project, **extra_issuable_attrs[0]) }
      let!(:issuable1) { create(:"labeled_#{issuable_type.singularize}", issuable_state, created_at: Time.utc(2018, 2, 1), labels: [label_bug, label_manage], project_association_key => project, **extra_issuable_attrs[1]) }
      let!(:issuable2) { create(:"labeled_#{issuable_type.singularize}", issuable_state, created_at: Time.utc(2019, 2, 6), labels: [label_bug, label_plan], project_association_key => project, **extra_issuable_attrs[2]) }
      let!(:issuable3) { create(:"labeled_#{issuable_type.singularize}", issuable_state, created_at: Time.utc(2019, 2, 20), labels: [label_bug, label_create], project_association_key => project, **extra_issuable_attrs[3]) }
      let!(:issuable4) { create(:"labeled_#{issuable_type.singularize}", issuable_state, created_at: Time.utc(2019, 3, 5), labels: [label_bug, label_quality], project_association_key => project, **extra_issuable_attrs[4]) }
      let(:query) do
        base_query.merge(
          issuable_type: issuable_type,
          issuable_state: issuable_state,
          filter_labels: [label_bug.title],
          collection_labels: [label_manage.title, label_plan.title, label_create.title])
      end

      let(:projects) { {} }

      subject { find(entity, query: query, projects: projects) }

      it 'avoids N + 1 queries' do
        control_queries = ActiveRecord::QueryRecorder.new { subject.map { |issuable| issuable.labels.map(&:title) } }
        create(:"labeled_#{issuable_type.singularize}", :opened, created_at: Time.utc(2019, 3, 5), labels: [label_bug], project_association_key => project, **extra_issuable_attrs[5])

        expect do
          find(entity, query: query).map { |issuable| issuable.labels.map(&:title) }
        end.not_to exceed_query_limit(control_queries)
      end

      context ':period_limit query' do
        context 'with group_by: "day"' do
          before do
            query.merge!(group_by: 'day')
          end

          it 'returns issuable created after 30 days ago' do
            expect(subject).to eq([issuable2, issuable3, issuable4])
          end
        end

        context 'with group_by: "day", period_limit: 1' do
          before do
            query.merge!(group_by: 'day', period_limit: 1)
          end

          it 'returns issuable created after one day ago' do
            expect(subject).to eq([issuable4])
          end
        end

        context 'with group_by: "week"' do
          before do
            query.merge!(group_by: 'week')
          end

          it 'returns issuable created after 12 weeks ago' do
            expect(subject).to eq([issuable2, issuable3, issuable4])
          end
        end

        context 'with group_by: "week", period_limit: 1' do
          before do
            query.merge!(group_by: 'week', period_limit: 1)
          end

          it 'returns issuable created after one week ago' do
            expect(subject).to eq([issuable4])
          end
        end

        context 'with group_by: "month"' do
          before do
            query.merge!(group_by: 'month')
          end

          it 'returns issuable created after 12 months ago' do
            expect(subject).to eq([issuable2, issuable3, issuable4])
          end
        end

        context 'with group_by: "month", period_limit: 1' do
          before do
            query.merge!(group_by: 'month', period_limit: 1)
          end

          it 'returns issuable created after one month ago' do
            expect(subject).to eq([issuable2, issuable3, issuable4])
          end
        end
      end

      context ':projects option' do
        let(:query) do
          { issuable_type: issuable_type, issuable_state: issuable_state }
        end

        before do
          # For merge requests we need to update both projects
          attributes =
            Hash[
              [
                [:project, other_project],
                [project_association_key, other_project]
              ].uniq
            ]

          issuable0.update!(attributes)
          issuable1.update!(attributes)
        end

        context 'when `projects.only` are specified by one id' do
          let(:projects) { { only: [project.id] } }

          it 'returns issuables for that project' do
            expect(subject).to eq([issuable2, issuable3, issuable4])
          end
        end

        context 'when `projects.only` are specified by two ids' do
          let(:projects) { { only: [project.id, other_project.id] } }

          it 'returns issuables for all valid projects' do
            expected = [issuable0, issuable1, issuable2, issuable3, issuable4]

            if entity.id == project.id
              expected.shift(2) # Those are from other_project
            end

            expect(subject).to eq(expected)
          end
        end

        context 'when `projects.only` are specified by bad id' do
          let(:projects) { { only: [0] } }

          it 'returns nothing' do
            expect(subject).to be_empty
          end
        end

        context 'when `projects.only` are specified by bad id and good id' do
          let(:projects) { { only: [0, project.id] } }

          it 'returns issuables for good project' do
            expect(subject).to eq([issuable2, issuable3, issuable4])
          end
        end

        context 'when `projects.only` are specified by one project full path' do
          let(:projects) { { only: [project.full_path] } }

          it 'returns issuables for that project' do
            expect(subject).to eq([issuable2, issuable3, issuable4])
          end
        end

        context 'when `projects.only` are specified by project full path and id' do
          let(:projects) { { only: [project.id, other_project.full_path] } }

          it 'returns issuables for all valid projects' do
            expected = [issuable0, issuable1, issuable2, issuable3, issuable4]

            if entity.id == project.id
              expected.shift(2) # Those are from other_project
            end

            expect(subject).to eq(expected)
          end
        end

        context 'when `projects.only` are specified by duplicated projects' do
          let(:projects) { { only: [project.id, project.full_path] } }

          it 'returns issuables for that project without duplicated issuables' do
            expect(subject).to eq([issuable2, issuable3, issuable4])
          end
        end

        context 'when `projects.only` are specified by bad project path' do
          let(:projects) { { only: [project.full_path.reverse] } }

          it 'returns nothing' do
            expect(subject).to be_empty
          end
        end

        context 'when `projects.only` are specified by unrelated project' do
          let(:projects) { { only: [create(:project, :public).id] } }

          it 'returns nothing' do
            expect(subject).to be_empty
          end
        end
      end
    end

    shared_examples_for 'group tests' do
      let(:entity) { create(:group) }
      let(:label_type) { :group_label }
      let(:label_entity_association_key) { :group }

      context 'issues' do
        include_examples "insights issuable finder" do
          let(:issuable_type) { 'issue' }
          let(:project_association_key) { :project }
        end
      end

      context 'merge requests' do
        include_examples "insights issuable finder" do
          let(:issuable_type) { 'merge_request' }
          let(:project_association_key) { :source_project }
          let(:extra_issuable_attrs) { merge_request_extra_attrs }
        end
      end
    end

    context 'for a group' do
      include_examples 'group tests' do
        let(:project) { create(:project, :public, group: entity) }
        let(:other_project) { create(:project, :public, group: entity) }
      end
    end

    context 'for a group with subgroups' do
      include_examples 'group tests' do
        let(:project) { create(:project, :public, group: create(:group, parent: entity)) }
        let(:other_project) { create(:project, :public, group: entity) }
      end
    end

    context 'for a project' do
      let(:project) { create(:project, :public) }
      let(:other_project) { create(:project, :public) }
      let(:entity) { project }
      let(:label_type) { :label }
      let(:label_entity_association_key) { :project }

      context 'issues' do
        include_examples "insights issuable finder" do
          let(:issuable_type) { 'issue' }
          let(:project_association_key) { :project }
        end
      end

      context 'merge requests' do
        include_examples "insights issuable finder" do
          let(:issuable_type) { 'merge_request' }
          let(:project_association_key) { :source_project }
          let(:extra_issuable_attrs) { merge_request_extra_attrs }
        end
      end

      context 'merged merge requests' do
        include_examples "insights issuable finder" do
          let(:issuable_state) { :merged }
          let(:issuable_type) { 'merge_request' }
          let(:project_association_key) { :source_project }
          let(:extra_issuable_attrs) { merge_request_extra_attrs }
        end
      end
    end
  end

  describe '#period_limit' do
    subject { described_class.new(create(:project, :public), nil, query: query).period_limit }

    describe 'default values' do
      context 'with group_by: "day"' do
        let(:query) { base_query.merge!(group_by: 'day') }

        it 'returns 30' do
          expect(subject).to eq(30)
        end
      end

      context 'with group_by: "week"' do
        let(:query) { base_query.merge!(group_by: 'week') }

        it 'returns 12' do
          expect(subject).to eq(12)
        end
      end

      context 'with group_by: "month"' do
        let(:query) { base_query.merge!(group_by: 'month') }

        it 'returns 12' do
          expect(subject).to eq(12)
        end
      end
    end

    describe 'custom values' do
      context 'with period_limit: 42' do
        let(:query) { base_query.merge!(period_limit: 42) }

        it 'returns 42' do
          expect(subject).to eq(42)
        end
      end

      context 'with an invalid period_limit' do
        let(:query) { base_query.merge!(period_limit: 'many') }

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::InvalidPeriodLimitError, "Invalid `:period_limit` option: `many`. Expected an integer!")
        end
      end
    end
  end
end
