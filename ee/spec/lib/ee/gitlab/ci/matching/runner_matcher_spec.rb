# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Matching::RunnerMatcher do
  let(:dummy_attributes) do
    {
      runner_ids: [1],
      runner_type: 'instance_type',
      public_projects_minutes_cost_factor: 0.0,
      private_projects_minutes_cost_factor: 1.0,
      run_untagged: false,
      access_level: 'ref_protected',
      tag_list: %w[tag1 tag2]
    }
  end

  describe '#matches_quota?' do
    let(:project) { build_stubbed(:project, project_attributes) }

    let(:build) do
      build_stubbed(:ci_build, project: project)
    end

    let(:runner_matcher) do
      described_class.new(dummy_attributes.merge(runner_attributes))
    end

    let(:visibility_map) do
      {
        public: ::Gitlab::VisibilityLevel::PUBLIC,
        internal: ::Gitlab::VisibilityLevel::INTERNAL,
        private: ::Gitlab::VisibilityLevel::PRIVATE
      }
    end

    subject { runner_matcher.matches_quota?(record) }

    shared_examples 'matches quota to runner types' do
      using RSpec::Parameterized::TableSyntax

      where(:runner_type, :project_visibility_level, :quota_minutes_used_up, :result) do
        :project_type   | :public                  | true                  | true
        :project_type   | :internal                | true                  | true
        :project_type   | :private                 | true                  | true

        :instance_type  | :public                  | true                  | true
        :instance_type  | :public                  | false                 | true

        :instance_type  | :internal                | true                  | false
        :instance_type  | :internal                | false                 | true

        :instance_type  | :private                 | true                  | false
        :instance_type  | :private                 | false                 | true
      end
      with_them do
        let(:runner_attributes) do
          { runner_type: runner_type }
        end

        let(:project_attributes) do
          { visibility_level: visibility_map[project_visibility_level] }
        end

        before do
          allow(project)
            .to receive(:ci_minutes_usage)
            .and_return(double(minutes_used_up?: quota_minutes_used_up, quota_enabled?: true))
        end

        it { is_expected.to eq(result) }
      end
    end

    context 'with an instance of BuildMatcher' do
      it_behaves_like 'matches quota to runner types' do
        let(:record) { build.build_matcher }
      end
    end

    context 'with an instance of Ci::Build' do
      it_behaves_like 'matches quota to runner types' do
        let(:record) { build }
      end
    end

    context 'N+1 queries check' do
      let_it_be(:project) { create(:project) }
      let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
      let_it_be(:build) { create(:ci_build, pipeline: pipeline, project: project, tag_list: %w[tag1 tag2]) }

      let(:runner_attributes) { {} }

      it 'does not generate N+1 queries when loading the quota for project' do
        project.reload
        control_count = ActiveRecord::QueryRecorder.new do
          runner_matcher.matches_quota?(build.build_matcher)
        end

        create(:ci_build, pipeline: pipeline, project: project, tag_list: %w[tag3 tag4])
        create(:ci_build, pipeline: pipeline, project: project, tag_list: %w[tag4 tag5])
        project.reload
        build_matchers = pipeline.builds.build_matchers(project)

        expect(build_matchers.size).to eq(3)

        expect do
          ActiveRecord::QueryRecorder.new do
            build_matchers.each do |matcher|
              runner_matcher.matches_quota?(matcher)
            end
          end
        end.not_to exceed_query_limit(control_count)
      end
    end
  end
end
