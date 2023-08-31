# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest, feature_category: :code_review_workflow do
  let_it_be(:project) { build(:project) }

  subject(:merge_request) { build(:merge_request, project: project) }

  describe '#can_suggest_reviewers?' do
    subject { merge_request.can_suggest_reviewers? }

    before do
      allow(merge_request).to receive(:modified_paths).and_return(['foo/bar.txt'])
    end

    context 'when open' do
      before do
        allow(merge_request).to receive(:open?).and_return(true)
      end

      it { is_expected.to be(true) }

      context 'when modified_paths is empty' do
        before do
          allow(merge_request).to receive(:modified_paths).and_return([])
        end

        it { is_expected.to be(false) }
      end
    end

    context 'when not open' do
      before do
        allow(merge_request).to receive(:open?).and_return(false)
      end

      it { is_expected.to be(false) }
    end
  end

  describe '#suggested_reviewer_users' do
    subject(:suggested_reviewer_users) { merge_request.suggested_reviewer_users }

    shared_examples 'blank suggestions' do
      it 'returns an empty relation' do
        expect(suggested_reviewer_users).to be_empty
      end
    end

    context 'when predictions is nil' do
      it_behaves_like 'blank suggestions'
    end

    context 'when predictions is not nil' do
      before do
        merge_request.build_predictions
      end

      context 'when predictions is a non hash' do
        before do
          merge_request.build_predictions
          merge_request.predictions.suggested_reviewers = 1
        end

        it_behaves_like 'blank suggestions'
      end

      context 'when predictions is an empty hash' do
        before do
          merge_request.predictions.suggested_reviewers = {}
        end

        it_behaves_like 'blank suggestions'
      end

      context 'when suggests a user who is not a member' do
        let_it_be(:non_member) { create(:user) }

        before do
          merge_request.predictions.suggested_reviewers = { 'reviewers' => [non_member.username] }
        end

        it_behaves_like 'blank suggestions'
      end

      context 'when suggests users who are members' do
        let_it_be(:first_member) { create(:user) }
        let_it_be(:second_member) { create(:user) }
        let_it_be(:bot_member) { create(:user, :project_bot) }
        let_it_be(:service_member) { create(:user, :service_user) }

        before_all do
          project.add_developer(first_member)
          project.add_developer(second_member)
          project.add_reporter(bot_member)
          project.add_reporter(service_member)
        end

        before do
          merge_request.predictions.suggested_reviewers = {
            'reviewers' => [
              second_member.username,
              first_member.username,
              bot_member.username,
              service_member.username
            ]
          }
        end

        context 'when a user is inactive' do
          before do
            second_member.deactivate
          end

          it 'returns only active human users' do
            expect(suggested_reviewer_users).to eq([first_member])
          end
        end

        context 'when all users are active' do
          it 'returns human users in correct suggested order' do
            expect(suggested_reviewer_users).to eq([second_member, first_member])
          end
        end
      end
    end
  end
end
