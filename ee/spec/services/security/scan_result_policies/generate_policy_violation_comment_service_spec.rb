# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::GeneratePolicyViolationCommentService, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  describe '#execute' do
    subject(:execute) { described_class.new(merge_request, violated_policy).execute }

    let_it_be(:bot_user) { User.security_bot }

    let(:expected_violation_note) { 'Policy violation(s) detected' }
    let(:expected_fixed_note) { 'Security policy violations have been resolved' }

    shared_examples 'successful service response' do
      it 'returns a successful service response' do
        result = execute

        expect(result).to be_kind_of(ServiceResponse)
        expect(result.success?).to eq(true)
      end
    end

    context 'when error occurs while saving the note' do
      let(:violated_policy) { true }

      before do
        errors_double = instance_double(ActiveModel::Errors, empty?: false, full_messages: ['error message'])
        allow_next_instance_of(::Note) do |note|
          allow(note).to receive(:save).and_return(false)
          allow(note).to receive(:errors).and_return(errors_double)
        end
      end

      it 'returns error details in the result' do
        result = execute

        expect(result.success?).to eq(false)
        expect(result.message).to contain_exactly('error message')
      end
    end

    context 'when there is no bot comment yet' do
      before do
        execute
      end

      context 'when policy has been violated' do
        let(:violated_policy) { true }

        it_behaves_like 'successful service response'

        it 'creates a comment' do
          note = merge_request.notes.last
          expect(note.note).to include(expected_violation_note)
          expect(note.author).to eq(bot_user)
        end
      end

      context 'when there was no policy violation' do
        let(:violated_policy) { false }

        it_behaves_like 'successful service response'

        it 'does not create a comment' do
          expect(merge_request.notes).to be_empty
        end
      end
    end

    context 'when there is already a bot comment' do
      let_it_be_with_reload(:bot_comment) do
        create(:note, project: project, noteable: merge_request, author: bot_user, note: 'Previous comment')
      end

      before do
        execute
      end

      context 'when policy has been violated' do
        let(:violated_policy) { true }

        it_behaves_like 'successful service response'

        it 'updates the comment with a violated note' do
          expect(bot_comment.note).to include(expected_violation_note)
        end
      end

      context 'when there was no policy violation' do
        let(:violated_policy) { false }

        it_behaves_like 'successful service response'

        it 'updates the comment with fixes note' do
          expect(bot_comment.note).to include(expected_fixed_note)
        end
      end
    end

    context 'when there is a comment from another user and there is a violation' do
      let(:violated_policy) { true }

      before do
        create(:note, project: project, noteable: merge_request, note: 'Other comment')

        execute
      end

      it_behaves_like 'successful service response'

      it 'creates a bot comment' do
        note = merge_request.notes.last

        expect(merge_request.notes.count).to eq(2)
        expect(note.note).to include(expected_violation_note)
      end
    end
  end
end
