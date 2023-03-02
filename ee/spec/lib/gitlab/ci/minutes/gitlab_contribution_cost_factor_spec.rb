# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Minutes::GitlabContributionCostFactor, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax
  include ProjectForksHelper

  let_it_be(:gitlab_group) { create(:group) }
  let_it_be(:another_group) { create(:group) }

  let(:gitlab_project) { create(:project, group: gitlab_group) }

  let(:another_project) { create(:project, group: another_group) }

  where(:fork_from, :is_merge_request, :target_project, :monthly_minutes, :expectation, :case_name) do
    ref(:gitlab_project)  | true  | ref(:gitlab_project)  | 10_000 | 0.0333     |  '10k minutes'
    ref(:gitlab_project)  | true  | ref(:gitlab_project)  | 50_000 | 0.1666     |  '50k minutes'
    ref(:gitlab_project)  | true  | ref(:gitlab_project)  | 400    | 0.0013     |  '400 minutes'
    ref(:gitlab_project)  | false | ref(:gitlab_project)  | 400    | nil        |  'not an MR pipeline'
    ref(:gitlab_project)  | true  | ref(:gitlab_project)  | 0      | nil        |  'Minute limit disabled'
    ref(:another_project) | true  | ref(:another_project) | 400    | nil        |  'non-GitLab project'
    nil                   | true  | ref(:gitlab_project)  | 400    | nil        |  'Not a fork'
  end

  with_them do
    # builds project is target_project for merge_request_event source pipelines
    let(:build) { create(:ci_build, project: target_project) }

    let(:source_project) do
      # If not forked then the target matches the source
      if fork_from
        fork_project(fork_from)
      else
        target_project
      end
    end

    before do
      stub_feature_flags(ci_minimal_cost_factor_for_gitlab_namespaces: gitlab_group)

      if is_merge_request
        merge_request = create(:merge_request,
          source_project: source_project,
          target_project: target_project
        )
        build.pipeline.update!(merge_request: merge_request)
      end

      build.project.root_namespace.update!(shared_runners_minutes_limit: monthly_minutes)
    end

    it 'returns the expected cost factor' do
      result = described_class.new(build.project, build.pipeline.merge_request).cost_factor

      expect(result&.floor(4)).to eq(expectation&.floor(4))
    end
  end
end
