# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::HandleAssigneesChangeService, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, author: user, source_project: project) }

  let(:old_assignees) { [] }
  let(:options) { {} }

  let(:service) { described_class.new(project: project, current_user: user) }

  describe '#execute' do
    def execute
      service.execute(merge_request, old_assignees, options)
    end

    it 'schedules for analytics metric update' do
      expect(Analytics::CodeReviewMetricsWorker)
        .to receive(:perform_async).with('Analytics::RefreshReassignData', merge_request.id)

      execute
    end

    context 'when code_review_analytics is not available' do
      before do
        stub_licensed_features(code_review_analytics: false)
      end

      it 'does not schedule for analytics metric update' do
        expect(Analytics::CodeReviewMetricsWorker).not_to receive(:perform_async)

        execute
      end
    end
  end
end
