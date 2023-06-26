# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ExternalPullRequests::ProcessGithubEventService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:action) { 'opened' }
  let(:params) do
    {
      pull_request: {
        number: 123,
        head: {
          ref: source_branch,
          sha: source_sha,
          repo: { full_name: 'the-repo' }
        },
        base: {
          ref: 'the-target-branch',
          sha: 'a09386439ca39abe575675ffd4b89ae824fec22f',
          repo: { full_name: 'the-repo' }
        }
      },
      action: action
    }
  end

  subject { described_class.new(project, user) }

  describe '#execute' do
    before do
      stub_licensed_features(ci_cd_projects: true, github_integration: true)
    end

    context 'when project is not a mirror' do
      let(:source_branch) { double }
      let(:source_sha) { double }

      it 'does nothing' do
        expect(subject.execute(params)).to be_nil
      end
    end

    context 'when project is a mirror' do
      before do
        allow(project).to receive(:mirror?).and_return(true)
      end

      context 'when the pull request record does not exist' do
        context 'when the pull request webhook occurs after mirror update' do
          let(:branch) { project.repository.branches.first }
          let(:source_branch) { branch.name }
          let(:source_sha) { branch.target }

          it 'enqueues Ci::ExternalPullRequests::CreatePipelineWorker' do
            expect { subject.execute(params) }
             .to change { ::Ci::ExternalPullRequest.count }.by(1)
             .and change { ::Ci::ExternalPullRequests::CreatePipelineWorker.jobs.count }.by(1)

            args = ::Ci::ExternalPullRequests::CreatePipelineWorker.jobs.last['args']
            pull_request = ::Ci::ExternalPullRequest.last

            expect(args[0]).to eq(project.id)
            expect(args[1]).to eq(user.id)
            expect(args[2]).to eq(pull_request.id)
          end
        end

        context 'when the pull request webhook occurs before mirror update' do
          let(:source_branch) { 'a-new-branch' }
          let(:source_sha) { 'non-existent-sha' }

          it 'only saves pull request info' do
            expect(Ci::CreatePipelineService).not_to receive(:new)

            expect { subject.execute(params) }.to change { ::Ci::ExternalPullRequest.count }.by(1)

            pull_request = ::Ci::ExternalPullRequest.last

            expect(pull_request).to be_persisted
            expect(pull_request.project).to eq(project)
            expect(pull_request.source_branch).to eq('a-new-branch')
            expect(pull_request.source_repository).to eq('the-repo')
            expect(pull_request.target_branch).to eq('the-target-branch')
            expect(pull_request.target_repository).to eq('the-repo')
            expect(pull_request.status).to eq('open')
          end
        end
      end

      context 'when the pull request record already exists' do
        let(:source_branch) { 'feature' }
        let(:source_sha) { '3d8151901da736dc432dff1f3d8e8f2bb59310e3' }
        let(:external_pull_request_status) { :open }

        before do
          create(:external_pull_request,
            project: project,
            source_branch: 'feature',
            source_sha: 'ce85aeb75247ab87b5f974adc78a924a335966fe',
            status: external_pull_request_status)
        end

        shared_examples 'updates pull request' do |pull_request_status|
          it 'updates the pull request without creating any pipeline' do
            expect(Ci::CreatePipelineService).not_to receive(:new)

            pull_request = subject.execute(params)

            expect(pull_request).to be_persisted
            expect(pull_request.project).to eq(project)
            expect(pull_request.source_branch).to eq('feature')
            expect(pull_request.source_sha).to eq(source_sha)
            expect(pull_request.source_repository).to eq('the-repo')
            expect(pull_request.target_branch).to eq('the-target-branch')
            expect(pull_request.target_repository).to eq('the-repo')
            expect(pull_request.status).to eq(pull_request_status)
          end
        end

        context 'when pull request webhook action is "synchronize"' do
          let(:action) { 'synchronize' }

          it_behaves_like 'updates pull request', 'open'
        end

        context 'when pull request webhook action is "closed"' do
          let(:action) { 'closed' }

          it_behaves_like 'updates pull request', 'closed'
        end

        context 'when pull request webhook action is "reopened"' do
          let(:external_pull_request_status) { :closed }
          let(:action) { 'reopened' }

          it_behaves_like 'updates pull request', 'open'
        end

        context 'when pull request webhook action is unsupported' do
          let(:action) { 'assigned' }

          it 'returns nil' do
            expect(subject.execute(params)).to be_nil
          end
        end

        context 'when pull request webhook any missing params' do
          let(:source_branch) { nil }
          let(:source_sha) { nil }

          it 'returns a pull request with errors' do
            expect(subject.execute(params).errors).not_to be_empty
          end
        end
      end
    end

    context 'without license' do
      let(:source_branch) { double }
      let(:source_sha) { double }

      before do
        allow(project).to receive(:mirror?).and_return(true)
        stub_licensed_features(ci_cd_projects: false, github_integration: false)
      end

      it 'does nothing' do
        expect(subject.execute(params)).to be_nil
      end
    end
  end
end
