# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::RelatedPipelinesFinder, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) do
    create(:ci_pipeline, :success, project: project, source: Enums::Ci::Pipeline.sources[:push])
  end

  let_it_be(:sha) { pipeline.sha }
  let_it_be(:params) { {} }

  let_it_be(:web_pipeline) do
    create(:ci_pipeline, :success, project: project, source: Enums::Ci::Pipeline.sources[:web], sha: sha)
  end

  let_it_be(:merge_request_pipeline_1) do
    create(:ci_pipeline, :running,
      project: project,
      source: Enums::Ci::Pipeline.sources[:merge_request_event],
      sha: sha
    )
  end

  let_it_be(:security_policy_pipeline) do
    create(:ci_pipeline, :success,
      project: project,
      source: Enums::Ci::Pipeline.sources[:security_orchestration_policy],
      sha: sha
    )
  end

  let_it_be(:merge_request_pipeline_2) do
    create(:ci_pipeline, :success,
      project: project,
      source: Enums::Ci::Pipeline.sources[:merge_request_event],
      sha: sha
    )
  end

  let_it_be(:web_pipeline_with_different_sha) do
    create(:ci_pipeline, :success, project: project, source: Enums::Ci::Pipeline.sources[:web], sha: 'sha2')
  end

  describe '#execute' do
    subject { described_class.new(pipeline, params).execute }

    context 'with sources' do
      let(:params) { { sources: Enums::Ci::Pipeline.ci_and_security_orchestration_sources.values } }

      it {
        is_expected.to contain_exactly(pipeline.id, web_pipeline.id, security_policy_pipeline.id,
          merge_request_pipeline_2.id)
      }
    end

    context 'with ref' do
      let(:params) do
        {
          sources: Enums::Ci::Pipeline.ci_and_security_orchestration_sources.values,
          ref: project.default_branch
        }
      end

      let_it_be(:tag_pipeline) do
        create(:ci_pipeline, :success,
          project: project,
          tag: true,
          sha: sha,
          ref: 'tag-v1',
          source: Enums::Ci::Pipeline.sources[:push]
        )
      end

      it {
        is_expected.to contain_exactly(pipeline.id, web_pipeline.id, security_policy_pipeline.id,
          merge_request_pipeline_2.id)
      }
    end

    context 'with merged_result_pipeline' do
      let_it_be(:pipeline) do
        create(:ci_pipeline, :merged_result_pipeline, :success, project: project)
      end

      let_it_be(:push_pipeline) do
        create(:ci_pipeline, :success, sha: sha, project: project, source: Enums::Ci::Pipeline.sources[:push])
      end

      let_it_be(:sha) { pipeline.source_sha }

      it { is_expected.to contain_exactly(pipeline.id, security_policy_pipeline.id, web_pipeline.id, push_pipeline.id) }
    end
  end
end
