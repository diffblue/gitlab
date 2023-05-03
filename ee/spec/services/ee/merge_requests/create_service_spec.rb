# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CreateService, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:service) { described_class.new(project: project, current_user: user, params: opts) }
  let(:opts) do
    {
      title: 'Awesome merge_request',
      description: 'please fix',
      source_branch: 'feature',
      target_branch: 'master',
      force_remove_source_branch: '1'
    }
  end

  before do
    allow(service).to receive(:execute_hooks)
  end

  describe '#execute' do
    let(:user) { create(:user) }

    before do
      project.add_maintainer(user)
    end

    it 'schedules refresh of code owners for the merge request' do
      Sidekiq::Testing.fake! do
        expect { service.execute }.to change(::MergeRequests::SyncCodeOwnerApprovalRulesWorker.jobs, :size).by(1)
        ::MergeRequests::SyncCodeOwnerApprovalRulesWorker.clear
      end
    end

    context 'report approvers' do
      it 'refreshes report approvers for the merge request' do
        expect_next_instance_of(::MergeRequests::SyncReportApproverApprovalRules) do |service|
          expect(service).to receive(:execute)
        end

        service.execute
      end
    end

    it_behaves_like 'new issuable with scoped labels' do
      let(:parent) { project }
      let(:service_result) { described_class.new(**args).execute }
      let(:issuable) { service_result }
    end

    it_behaves_like 'service with multiple reviewers' do
      let(:execute) { service.execute }
    end

    it_behaves_like 'service with approval rules' do
      let(:execute) { service.execute }
    end

    it 'sends the audit streaming event' do
      audit_context = {
        name: 'merge_request_create',
        stream_only: true,
        author: user,
        scope: project,
        message: 'Added merge request'
      }

      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(audit_context))

      service.execute
    end
  end

  describe '#execute with blocking merge requests', :clean_gitlab_redis_shared_state do
    let(:opts) { { title: 'Blocked MR', source_branch: 'feature', target_branch: 'master' } }
    let(:user) { project.first_owner }

    it 'delegates to MergeRequests::UpdateBlocksService' do
      expect(MergeRequests::UpdateBlocksService)
        .to receive(:extract_params!)
        .and_return(:extracted_params)

      expect_next_instance_of(MergeRequests::UpdateBlocksService) do |block_service|
        expect(block_service.merge_request.title).to eq('Blocked MR')
        expect(block_service.current_user).to eq(user)
        expect(block_service.params).to eq(:extracted_params)

        expect(block_service).to receive(:execute)
      end

      service.execute
    end
  end
end
