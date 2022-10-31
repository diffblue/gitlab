# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Github::StatusMessage do
  include Rails.application.routes.url_helpers

  let(:project) { double(:project, namespace: "me", to_s: 'example_project') }
  let(:integration) { double(:integration, static_context?: false) }

  before do
    stub_config_setting(host: 'instance-host')
  end

  describe '#description' do
    it 'includes human readable gitlab status' do
      subject = described_class.new(project, integration, detailed_status: 'passed')

      expect(subject.description).to eq "Pipeline passed on GitLab"
    end

    it 'gets truncated to 140 chars' do
      dummy_text = 'a' * 500
      subject = described_class.new(project, integration, detailed_status: dummy_text)

      expect(subject.description.length).to eq 140
    end
  end

  describe '#status' do
    using RSpec::Parameterized::TableSyntax

    where(:gitlab_status, :github_status) do
      'pending'  | :pending
      'created'  | :pending
      'running'  | :pending
      'manual'   | :pending
      'success'  | :success
      'skipped'  | :success
      'failed'   | :failure
      'canceled' | :error
    end

    with_them do
      it 'transforms status' do
        subject = described_class.new(project, integration, status: gitlab_status)

        expect(subject.status).to eq github_status
      end
    end
  end

  describe '#status_options' do
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

    let(:subject) { described_class.new(project, integration, id: pipeline.id) }

    it 'includes context' do
      expect(subject.status_options[:context]).to be_a String
    end

    it 'includes target_url' do
      expect(subject.status_options[:target_url]).to be_a String
    end

    it 'includes description' do
      expect(subject.status_options[:description]).to be_a String
    end
  end

  describe '#context' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:child_pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:grandchild_pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:other_pipeline) { create(:ci_pipeline, project: other_project) }

    before_all do
      create(:ci_sources_pipeline,
        source_job: create(:ci_build, pipeline: pipeline, name: 'child'),
        source_project: project,
        pipeline: child_pipeline,
        project: project)
      create(:ci_sources_pipeline,
        source_job: create(:ci_build, pipeline: child_pipeline, name: 'grandchild'),
        source_project: project,
        pipeline: grandchild_pipeline,
        project: project)
      create(:ci_sources_pipeline,
        source_job: create(:ci_build, pipeline: child_pipeline, name: 'other'),
        source_project: project,
        pipeline: other_pipeline,
        project: other_project)
    end

    subject do
      described_class.new(project, integration, ref: 'some-ref', id: pipeline_id)
    end

    context 'when status context is supposed to be dynamic' do
      before do
        allow(integration).to receive(:static_context?).and_return(false)
      end

      context 'when parent pipeline is used' do
        let(:pipeline_id) { pipeline.id }

        it 'appends pipeline reference to the status context' do
          expect(subject.context).to eq 'ci/gitlab/some-ref'
        end

        context 'when child pipeline is used' do
          let(:pipeline_id) { child_pipeline.id }

          it 'appends job name to status context' do
            expect(subject.context).to eq 'ci/gitlab/some-ref/child'
          end
        end
      end
    end

    context 'when status context is supposed to be static' do
      before do
        allow(integration).to receive(:static_context?).and_return(true)
      end

      context 'when parent pipeline is used' do
        let(:pipeline_id) { pipeline.id }

        it 'appends instance hostname to the status context' do
          expect(subject.context).to eq 'ci/gitlab/instance-host'
        end
      end

      context 'when child pipeline is used' do
        let(:pipeline_id) { child_pipeline.id }

        it 'appends job name to status context' do
          expect(subject.context).to eq 'ci/gitlab/instance-host/child'
        end
      end

      context 'when grandchild pipeline is used' do
        let(:pipeline_id) { grandchild_pipeline.id }

        it 'appends all ancestor job names to status context' do
          expect(subject.context).to eq 'ci/gitlab/instance-host/child/grandchild'
        end
      end

      context 'when child pipeline in another project is used' do
        let(:pipeline_id) { other_pipeline.id }

        it 'does not append job name to the status context' do
          expect(subject.context).to eq 'ci/gitlab/instance-host'
        end
      end
    end
  end

  describe '.from_pipeline_data' do
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, ref: 'some-ref', project: project) }
    let(:sample_data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

    subject do
      described_class.from_pipeline_data(project, integration, sample_data)
    end

    it 'builds an instance of Integrations::Github::StatusMessage' do
      expect(subject).to be_a described_class
    end

    describe 'builds an object with' do
      specify 'sha' do
        expect(subject.sha).to eq pipeline.sha
      end

      specify 'status' do
        expect(subject.status).to eq :pending
      end

      specify 'pipeline_id' do
        expect(subject.pipeline_id).to eq pipeline.id
      end

      specify 'target_url' do
        expect(subject.target_url).to end_with pipeline_path(pipeline)
      end

      specify 'description' do
        expect(subject.description).to eq "Pipeline pending on GitLab"
      end

      specify 'context' do
        expect(subject.context).to eq "ci/gitlab/some-ref"
      end

      context 'when pipeline is blocked' do
        let_it_be(:pipeline) { create(:ci_pipeline, :blocked) }

        it 'uses human readable status which can be used in a sentence' do
          expect(subject.description).to eq 'Pipeline waiting for manual action on GitLab'
        end
      end

      context 'when static context has been configured' do
        before do
          allow(integration).to receive(:static_context?).and_return(true)
        end

        subject do
          described_class.from_pipeline_data(project, integration, sample_data)
        end

        it 'appends instance name to the context name' do
          expect(subject.context).to eq "ci/gitlab/instance-host"
        end
      end

      context 'with child pipelines' do
        let_it_be(:child_pipeline_1) { create(:ci_pipeline, ref: 'some-ref', project: project) }
        let_it_be(:child_pipeline_2) { create(:ci_pipeline, ref: 'some-ref', project: project) }
        let(:child_data_1) { Gitlab::DataBuilder::Pipeline.build(child_pipeline_1) }
        let(:child_data_2) { Gitlab::DataBuilder::Pipeline.build(child_pipeline_2) }
        let(:parent_status) { subject }
        let(:child_status_1) { described_class.from_pipeline_data(project, integration, child_data_1) }
        let(:child_status_2) { described_class.from_pipeline_data(project, integration, child_data_2) }

        before_all do
          create(:ci_sources_pipeline,
            source_job: create(:ci_build, pipeline: pipeline, name: 'child_1'),
            source_project: project,
            pipeline: child_pipeline_1,
            project: project)
          create(:ci_sources_pipeline,
            source_job: create(:ci_build, pipeline: pipeline, name: 'child_2'),
            source_project: project,
            pipeline: child_pipeline_2,
            project: project)
        end

        it 'assigns a unique context to each pipeline' do
          expect(parent_status.context).not_to eq child_status_1.context
          expect(parent_status.context).not_to eq child_status_2.context
          expect(child_status_1.context).not_to eq child_status_2.context
        end
      end
    end
  end
end
