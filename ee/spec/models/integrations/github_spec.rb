# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Github do
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:pipeline_sample_data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }
  let(:owner) { 'my-user' }
  let(:token) { 'aaaaaaaaa' }
  let(:repository_name) { 'my-project' }
  let(:base_url) { 'https://github.com' }
  let(:repository_url) { "#{base_url}/#{owner}/#{repository_name}" }
  let(:integration_params) do
    {
      active: true,
      project: project,
      properties: {
        token: token,
        repository_url: repository_url
      }
    }
  end

  subject { described_class.create!(integration_params) }

  before do
    stub_licensed_features(github_integration: true)
  end

  describe 'default values' do
    it { expect(subject.pipeline_events).to eq(true) }
  end

  it_behaves_like Integrations::ResetSecretFields do
    let(:integration) { subject }
  end

  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  describe "Validations" do
    context 'when base_url is a localhost url' do
      let(:base_url) { 'http://127.0.0.1' }

      describe '#valid?' do
        it 'is not valid' do
          expect(described_class.new(integration_params)).not_to be_valid
        end
      end
    end
  end

  describe "#owner" do
    it 'is determined from the repo URL' do
      expect(subject.owner).to eq owner
    end
  end

  describe "#repository_name" do
    it 'is determined from the repo URL' do
      expect(subject.repository_name).to eq repository_name
    end
  end

  describe "#api_url" do
    it 'uses github.com by default' do
      expect(subject.api_url).to eq "https://api.github.com"
    end

    context "with GitHub Enterprise repo URL" do
      let(:base_url) { 'https://my.code-repo.com' }

      it 'is set to the Enterprise API URL' do
        expect(subject.api_url).to eq "https://my.code-repo.com/api/v3"
      end
    end
  end

  describe '#help' do
    it 'links to mirroring settings' do
      expect(subject.help).to match(/href=.*mirroring/)
    end
  end

  describe '#properties' do
    let(:properties) { subject.reload.properties.symbolize_keys }

    it 'does not overwrite existing integrations' do
      subject.update!(integration_params.slice(:properties))

      expect(properties).to match(integration_params[:properties])
      expect(subject.static_context).to be_nil
    end

    context 'when initialized without properties' do
      let(:integration_params) do
        {
          active: false,
          project: project
        }
      end

      it 'static_context defaults to true' do
        expect(properties).to match(static_context: true)
      end
    end

    context 'when initialized with static_context as false' do
      let(:integration_params) do
        {
          active: false,
          project: project,
          static_context: false
        }
      end

      it 'static_context remains false' do
        expect(properties).to match(static_context: false)
      end
    end

    context 'when initialized with static_context as false' do
      let(:integration_params) do
        {
          active: false,
          project: project,
          properties: { static_context: false }
        }
      end

      it 'static_context remains false' do
        expect(properties).to match(static_context: false)
      end
    end
  end

  describe '#execute' do
    let(:remote_repo_path) { "#{owner}/#{repository_name}" }
    let(:sha) { pipeline.sha }
    let(:status_options) { { context: 'security', target_url: 'https://localhost.pipeline.example.com', description: "SAST passed" } }
    let(:status_message) { double(sha: sha, status: :success, status_options: status_options) }
    let(:notifier) { instance_double(Integrations::Github::StatusNotifier) }
    let(:api_response) { instance_double(Sawyer::Response) }

    context 'the integration is invalid' do
      it 'does not notify GitHub of a status change' do
        allow(subject).to receive(:invalid?).and_return(true)

        expect(Integrations::Github::StatusMessage).not_to receive(:from_pipeline_data)

        subject.execute(pipeline_sample_data)
      end
    end

    it 'notifies GitHub of a status change' do
      expect(notifier).to receive(:notify)
      expect(notifier).to receive(:last_client_response)
      expect(Integrations::Github::StatusNotifier).to receive(:new).with(token, remote_repo_path, anything)
                                                            .and_return(notifier)

      subject.execute(pipeline_sample_data)
    end

    it 'uses StatusMessage to build message' do
      allow(subject).to receive(:update_status)

      expect(Integrations::Github::StatusMessage)
        .to receive(:from_pipeline_data)
        .with(project, subject, pipeline_sample_data)
        .and_return(status_message)

      subject.execute(pipeline_sample_data)
    end

    describe 'passes StatusMessage values to StatusNotifier' do
      before do
        allow(Integrations::Github::StatusNotifier).to receive(:new).and_return(notifier)
        allow(api_response).to receive(:status).and_return(201)
        allow(notifier).to receive(:last_client_response).and_return(api_response)
        allow(status_message).to receive(:pipeline_id).and_return(pipeline.id)
        allow(Integrations::Github::StatusMessage).to receive(:from_pipeline_data).and_return(status_message)
      end

      specify 'sha' do
        expect(notifier).to receive(:notify).with(sha, anything, anything)

        subject.execute(pipeline_sample_data)
      end

      specify 'status' do
        expected_status = status_message.status
        expect(notifier).to receive(:notify).with(anything, expected_status, anything)

        subject.execute(pipeline_sample_data)
      end

      specify 'context' do
        expected_context = status_options[:context]
        expect(notifier).to receive(:notify).with(anything, anything, hash_including(context: expected_context))

        subject.execute(pipeline_sample_data)
      end

      specify 'target_url' do
        expected_target_url = status_options[:target_url]
        expect(notifier).to receive(:notify).with(anything, anything, hash_including(target_url: expected_target_url))

        subject.execute(pipeline_sample_data)
      end

      specify 'description' do
        expected_description = status_options[:description]
        expect(notifier).to receive(:notify).with(anything, anything, hash_including(description: expected_description))

        subject.execute(pipeline_sample_data)
      end
    end

    it 'uses GitHub API to update status' do
      github_status_api = "https://api.github.com/repos/#{owner}/#{repository_name}/statuses/#{sha}"
      stub_request(:post, github_status_api).to_return(
        status: 200,
        body: { id: 1, state: 'success' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

      subject.execute(pipeline_sample_data)

      expect(a_request(:post, github_status_api)).to have_been_made.once
    end

    context 'with custom api endpoint' do
      let(:api_url) { 'https://my.code.repo' }

      before do
        allow(subject).to receive(:api_url).and_return(api_url)
      end

      it 'hands custom api url to StatusNotifier' do
        allow(notifier).to receive(:notify)
        allow(notifier).to receive(:last_client_response)
        expect(Integrations::Github::StatusNotifier).to receive(:new).with(anything, anything, api_endpoint: api_url)
                                                              .and_return(notifier)

        subject.execute(pipeline_sample_data)
      end
    end

    context 'when an external pull request pipeline exists' do
      let(:external_pr) { create(:external_pull_request, project: project) }

      let!(:external_pipeline) do
        create(:ci_pipeline,
          source: :external_pull_request_event,
          external_pull_request: external_pr,
          project: project)
      end

      it 'does not send notification' do
        expect(subject).not_to receive(:update_status)
        expect(Integrations::Github::StatusMessage).not_to receive(:from_pipeline_data)

        expect(subject.execute(pipeline_sample_data)).to be_nil
      end

      it 'sends notification if the sha is not present' do
        pipeline_sample_data[:object_attributes].delete(:sha)

        expect(subject).to receive(:update_status)
        expect(Integrations::Github::StatusMessage).to receive(:from_pipeline_data)

        subject.execute(pipeline_sample_data)
      end
    end

    context 'when the pipeline is an external pull request pipeline' do
      let(:external_pr) { create(:external_pull_request, project: project) }
      let(:notifier) { instance_double(Integrations::Github::StatusNotifier) }
      let(:api_response) { instance_double(Sawyer::Response) }
      let(:response_result) do
        {
          "id": 1234,
          "node_id": "FOO_BAR",
          "state": "success",
          "description": "Pipeline passed on GitLab",
          "target_url": "https://gitlab.example.com/pipelines/1234",
          "context": "ci/gitlab/gitlab.example.com",
          "created_at": "2022-05-20T09:04:21.000Z",
          "updated_at": "2022-05-20T09:04:22.000Z",
          "avatar_url": "https://gitlab.example.com/avatar-ignored.png",
          "creator": { "section_not_to_be_logged": "some_ignored_value" }
        }
      end

      before do
        pipeline.update!(
          source: :external_pull_request_event,
          external_pull_request: external_pr)
      end

      it 'sends notification' do
        expect(subject).to receive(:update_status)
        expect(Integrations::Github::StatusMessage).to receive(:from_pipeline_data)

        subject.execute(pipeline_sample_data)
      end

      it 'logs result of GitHub API call without the "creator" section and "avatar_url" field' do
        expect(subject).to receive(:notifier).twice.and_return(notifier)
        expect(notifier).to receive(:notify).once.and_return(response_result)
        expect(notifier).to receive(:last_client_response).once.and_return(api_response)
        expect(api_response).to receive(:status).once.and_return(201)

        expect(subject).to receive(:log_info).once.with(
          "GitHub Commit Status update API call succeeded",
          {
            github_response: response_result.except(:creator, :avatar_url),
            github_response_status: 201,
            pipeline_id: pipeline.id,
            pipeline_status: pipeline.status.to_sym
          }
        )

        subject.execute(pipeline_sample_data)
      end
    end

    context 'without a license' do
      it 'does nothing' do
        stub_licensed_features(github_integration: false)

        result = subject.execute(pipeline_sample_data)

        expect(result).to be_nil
      end
    end
  end

  describe '#testable?' do
    it 'is false if there are no pipelines' do
      project.ci_pipelines.delete_all

      expect(subject).not_to be_testable
    end

    it 'is true if the project has a pipeline' do
      pipeline

      expect(subject).to be_testable
    end
  end

  describe '#test' do
    it 'mentions creator in success message' do
      dummy_response = { context: "default", creator: { login: "YourUser" } }
      allow(subject).to receive(:update_status).and_return(dummy_response)

      result = subject.test(pipeline_sample_data)

      expect(result[:success]).to eq true
      expect(result[:result].to_s).to eq('Status for default updated by YourUser')
    end

    it 'forwards failure message on error' do
      error_response = { method: :post, status: 401, url: 'https://api.github.com/repos/my-user/my-project/statuses/master', body: 'Bad credentials' }
      allow(subject).to receive(:update_status).and_raise(Octokit::Unauthorized, error_response)

      result = subject.test(pipeline_sample_data)

      expect(result[:success]).to eq false
      expect(result[:result].to_s).to end_with('401 - Bad credentials')
    end

    context 'without a license' do
      it 'fails gracefully' do
        stub_licensed_features(github_integration: false)

        result = subject.test(pipeline_sample_data)

        expect(result[:success]).to eq false
      end
    end
  end
end
