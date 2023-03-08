# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateReviewersService, feature_category: :code_review_workflow do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :private, :repository, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }

  let_it_be_with_reload(:merge_request) do
    create(:merge_request, :simple, :unique_branches,
           reviewer_ids: [user.id],
           source_project: project,
           author: user)
  end

  before do
    project.add_maintainer(user)
    project.add_developer(user2)
    project.add_developer(user3)
  end

  let(:service) { described_class.new(project: project, current_user: user, params: opts) }

  describe 'execute' do
    def set_reviewers
      service.execute(merge_request)
      merge_request.reload
    end

    context 'when the parameters are valid' do
      context 'when using sentinel values' do
        let(:opts) { { reviewer_ids: [0, 0, 0] } }

        it 'removes all reviewers' do
          expect { set_reviewers }.to change(merge_request, :reviewers).to([])
        end
      end

      context 'when the reviewer_ids parameter is the empty list' do
        let(:opts) { { reviewer_ids: [] } }

        it 'removes all reviewers' do
          expect { set_reviewers }.to change(merge_request, :reviewers).to([])
        end
      end

      context 'when the reviewer_ids parameter contains both zeros and valid IDs' do
        let(:opts) { { reviewer_ids: [0, user2.id, 0, user3.id, 0] } }

        it 'ignores 0 IDs' do
          expect { set_reviewers }.to change(merge_request, :reviewers).to(match_array([user2, user3]))
        end
      end
    end
  end
end
