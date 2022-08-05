# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::SetReviewers do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request, reload: true) { create(:merge_request) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:reviewers) { create_list(:user, 3) }

    let(:mode) { Types::MutationOperationModeEnum.default_mode }
    let(:reviewer_usernames) { reviewers.map(&:username) }
    let(:mutated_merge_request) { subject[:merge_request] }

    subject do
      mutation.resolve(project_path: merge_request.project.full_path,
                       iid: merge_request.iid,
                       operation_mode: mode,
                       reviewer_usernames: reviewer_usernames)
    end

    before do
      reviewers.each do |user|
        merge_request.project.add_developer(user)
      end
    end

    context 'when the user can update the merge_request' do
      before do
        merge_request.project.add_developer(user)
      end

      it 'sets the reviewers' do
        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request.reviewers).to match_array(reviewers)
        expect(subject[:errors]).to be_empty
      end

      it 'removes reviewers not in the list' do
        users = create_list(:user, 2)
        users.each do |user|
          merge_request.project.add_developer(user)
        end
        merge_request.reviewers = users
        merge_request.save!

        expect(mutated_merge_request).to eq(merge_request)
        expect(mutated_merge_request.reviewers).to match_array(reviewers)
        expect(subject[:errors]).to be_empty
      end

      context 'when passing "append" as true' do
        subject do
          mutation.resolve(
            project_path: merge_request.project.full_path,
            iid: merge_request.iid,
            reviewer_usernames: reviewer_usernames,
            operation_mode: Types::MutationOperationModeEnum.enum[:append]
          )
        end

        let(:existing_reviewers) { create_list(:user, 2) }

        before do
          existing_reviewers.each do |user|
            merge_request.project.add_developer(user)
          end
          merge_request.reviewers = existing_reviewers
          merge_request.save!
        end

        it 'does not remove reviewers not in the list' do
          expect(mutated_merge_request).to eq(merge_request)
          expect(mutated_merge_request.reviewers).to match_array(reviewers + existing_reviewers)
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
