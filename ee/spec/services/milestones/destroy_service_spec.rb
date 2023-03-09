# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Milestones::DestroyService, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:milestone) { create(:milestone, title: 'Milestone v1.0', project: project) }

  before do
    project.add_maintainer(user)
  end

  def service
    described_class.new(project, user, {})
  end

  describe '#execute' do
    context 'with an existing merge request' do
      let!(:issue) { create(:issue, project: project, milestone: milestone) }
      let!(:merge_request) { create(:merge_request, source_project: project, milestone: milestone) }

      it 'manually queues MergeRequests::SyncCodeOwnerApprovalRulesWorker jobs' do
        expect(::MergeRequests::SyncCodeOwnerApprovalRulesWorker).to receive(:perform_async).with(merge_request.id)

        service.execute(milestone)
      end
    end
  end
end
