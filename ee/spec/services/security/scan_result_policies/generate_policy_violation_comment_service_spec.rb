# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::GeneratePolicyViolationCommentService, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let(:report_type) { 'scan_finding' }
  let(:requires_approval) { true }

  describe '#execute' do
    subject(:execute) { service.execute }

    let_it_be(:bot_user) { Users::Internal.security_bot }

    let(:service) { described_class.new(merge_request, params) }
    let(:params) do
      { 'report_type' => report_type, 'violated_policy' => violated_policy, requires_approval: requires_approval }
    end

    let(:expected_violation_note) { 'Policy violation(s) detected' }
    let(:expected_optional_approvals_note) { 'Consider including optional reviewers' }
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

    context 'when error occurs while trying to obtain the lock' do
      let(:violated_policy) { true }

      before do
        allow(service).to receive(:in_lock).and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
      end

      it 'returns error details in the result' do
        result = execute

        expect(result.success?).to eq(false)
        expect(result.message).to contain_exactly('Failed to obtain an exclusive lock')
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
          expect(note.note).to include(expected_violation_note, report_type)
          expect(note.author).to eq(bot_user)
        end
      end

      context 'when policy has been violated with optional approvals' do
        let(:violated_policy) { true }
        let(:requires_approval) { false }

        it_behaves_like 'successful service response'

        it 'creates a comment' do
          note = merge_request.notes.last
          expect(note.note).to include(expected_optional_approvals_note, report_type)
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
      let(:violated_reports) { [report_type] }
      let!(:bot_comment) do
        create(:note, project: project, noteable: merge_request, author: bot_user,
          note: [
            Security::ScanResultPolicies::PolicyViolationComment::MESSAGE_HEADER,
            "<!-- violated_reports: #{violated_reports}-->",
            "Previous comment"
          ].join("\n"))
      end

      before do
        execute
        bot_comment.reload
      end

      context 'when policy has been violated' do
        let(:violated_policy) { true }

        it_behaves_like 'successful service response'

        it 'updates the comment with a violated note' do
          expect(bot_comment.note).to include(expected_violation_note)
        end

        context 'when the existing violation was from another report_type' do
          let(:violated_reports) { 'license_scanning' }
          let(:report_type) { 'scan_finding' }

          it 'updates the comment with a violated note and extends existing violated reports' do
            expect(bot_comment.note).to include(expected_violation_note)
            expect(bot_comment.note).to include('license_scanning,scan_finding')
          end
        end
      end

      context 'when policy has been violated with optional approvals' do
        let(:violated_policy) { true }
        let(:requires_approval) { false }

        it_behaves_like 'successful service response'

        it 'updates the comment with a violated note' do
          expect(bot_comment.note).to include(expected_optional_approvals_note)
        end

        context 'when the existing violation required approvals and was from another report_type' do
          let(:violated_reports) { 'license_scanning' }
          let(:report_type) { 'scan_finding' }

          it 'updates the comment with a violated note and extends existing violated reports' do
            expect(bot_comment.note).to include(expected_violation_note)
            expect(bot_comment.note).to include('license_scanning,scan_finding')
          end
        end
      end

      context 'when there was no policy violation' do
        let(:violated_policy) { false }

        it_behaves_like 'successful service response'

        it 'updates the comment with fixes note' do
          expect(bot_comment.note).to include(expected_fixed_note)
        end

        context 'when the existing violation was from another report_type' do
          let(:violated_reports) { 'license_scanning' }
          let(:report_type) { 'scan_finding' }

          it 'updates the comment with an expected violation note and keeps existing violated reports' do
            expect(bot_comment.note).to include(expected_violation_note)
            expect(bot_comment.note).to include('license_scanning')
          end
        end
      end
    end

    context 'when there is another comment by security_bot' do
      let(:violated_policy) { true }
      let_it_be_with_reload(:other_bot_comment) do
        create(:note, project: project, noteable: merge_request, author: bot_user, note: 'Previous comment')
      end

      it_behaves_like 'successful service response'

      it 'creates a new comment with a violated note' do
        expect { execute }.to change { merge_request.notes.count }.by(1)

        bot_comment = merge_request.notes.last

        expect(other_bot_comment.note).to eq('Previous comment')
        expect(bot_comment.note).to include(expected_violation_note)
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
        bot_comment = merge_request.notes.last

        expect(merge_request.notes.count).to eq(2)
        expect(bot_comment.note).to include(expected_violation_note)
      end
    end
  end
end
