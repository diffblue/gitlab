# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::NewEpicIssueWorker, feature_category: :portfolio_management do
  describe '#perform' do
    let_it_be(:epic) { create(:epic) }
    let_it_be(:issue) { create(:issue) }
    let_it_be(:user) { create(:user) }

    let(:params) { { 'epic_id' => epic.id, 'issue_id' => issue.id, 'user_id' => user.id } }
    let(:extra_params) { {} }

    subject(:perform) { described_class.new.perform(params.merge(extra_params)) }

    shared_examples 'performs successfully' do |action_type|
      it 'creates system notes' do
        if action_type == :moved
          expect(SystemNoteService).to receive(:epic_issue_moved)
          expect(SystemNoteService).to receive(:issue_epic_change)
        else
          expect(SystemNoteService).to receive(:epic_issue)
          expect(SystemNoteService).to receive(:issue_on_epic)
        end

        subject
      end

      it 'updates usage data' do
        expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_issue_added)
          .with(author: user, namespace: epic.group)

        subject
      end
    end

    shared_examples 'does nothing' do
      it 'does not create system notes' do
        expect(SystemNoteService).not_to receive(:epic_issue_moved)
        expect(SystemNoteService).not_to receive(:issue_epic_change)
        expect(SystemNoteService).not_to receive(:epic_issue)
        expect(SystemNoteService).not_to receive(:issue_on_epic)
      end

      it 'does not update usage data' do
        expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).not_to receive(:track_epic_issue_added)
          .with(author: user, namespace: epic.group)
      end
    end

    it_behaves_like 'performs successfully'

    context 'when reassinging an issue' do
      let_it_be(:orig_epic) { create(:epic) }

      let(:extra_params) { { 'original_epic_id' => orig_epic.id } }

      it_behaves_like 'performs successfully', :moved

      context 'when original epic does not exist' do
        let(:extra_params) { { 'original_epic_id' => non_existing_record_id } }

        it_behaves_like 'does nothing'
      end
    end

    context 'when epic does not exist' do
      let(:extra_params) { { 'epic_id' => non_existing_record_id } }

      it_behaves_like 'does nothing'
    end

    context 'when issue does not exist' do
      let(:extra_params) { { 'issue_id' => non_existing_record_id } }

      it_behaves_like 'does nothing'
    end

    context 'when user does not exist' do
      let(:extra_params) { { 'user_id' => non_existing_record_id } }

      it_behaves_like 'does nothing'
    end
  end
end
