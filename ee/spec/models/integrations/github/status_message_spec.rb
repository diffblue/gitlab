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
    let(:subject) { described_class.new(project, integration, id: 1) }

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
    subject do
      described_class.new(project, integration, ref: 'some-ref')
    end

    context 'when status context is supposed to be dynamic' do
      before do
        allow(integration).to receive(:static_context?).and_return(false)
      end

      it 'appends pipeline reference to the status context' do
        expect(subject.context).to eq 'ci/gitlab/some-ref'
      end
    end

    context 'when status context is supposed to be static' do
      before do
        allow(integration).to receive(:static_context?).and_return(true)
      end

      it 'appends instance hostname to the status context' do
        expect(subject.context).to eq 'ci/gitlab/instance-host'
      end
    end
  end

  describe '.from_pipeline_data' do
    let(:project) { create(:project) }
    let(:pipeline) { create(:ci_pipeline, ref: 'some-ref', project: project) }
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
        let(:pipeline) { create(:ci_pipeline, :blocked) }

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
          expect(subject.context).to eq 'ci/gitlab/instance-host'
        end
      end
    end
  end
end
