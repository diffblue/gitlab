# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Llm::SummarizeMergeRequestWorker, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project) { merge_request.project }
  let_it_be(:message) { 'this is a message from the llm' }

  subject(:worker) { described_class.new }

  before do
    allow_next_instance_of(::Llm::MergeRequests::SummarizeDiffService,
      title: merge_request.title,
      user: user,
      diff: merge_request.merge_request_diff) do |service|
      allow(service).to receive(:execute).and_return(message)
    end
  end

  context "when provided an invalid user_id" do
    let(:params) { [non_existing_record_id, { merge_request_id: merge_request.id }] }

    it "returns nil" do
      expect(worker.perform(*params)).to be_nil
    end

    it "does not create a new note" do
      expect { worker.perform(*params) }.not_to change { Note.count }
    end
  end

  context 'when type is summarize_quick_action' do
    let(:params) do
      [user.id,
        { merge_request_id: merge_request.id,
          type: ::MergeRequests::Llm::SummarizeMergeRequestWorker::SUMMARIZE_QUICK_ACTION }]
    end

    context "when provided an invalid merge_request_id" do
      let(:params) do
        [user.id,
          { merge_request_id: non_existing_record_id,
            type: ::MergeRequests::Llm::SummarizeMergeRequestWorker::SUMMARIZE_QUICK_ACTION }]
      end

      it "returns nil" do
        expect(worker.perform(*params)).to be_nil
      end

      it "does not create a new note" do
        expect { worker.perform(*params) }.not_to change { Note.count }
      end
    end

    context "when user is not able to create new notes" do
      it "returns nil" do
        expect(worker.perform(*params)).to be_nil
      end

      it "does not create a new note" do
        expect { worker.perform(*params) }.not_to change { Note.count }
      end
    end

    context "when user can create new notes" do
      before do
        project.add_developer(user)
      end

      it "creates a note with the returned content" do
        note = worker.perform(*params)

        expect(note.note)
          .to include(message)
      end

      it "creates a new note" do
        expect { worker.perform(*params) }
          .to change { Note.count }.by(1)
      end

      it "creates a new note by the llm_bot" do
        note = worker.perform(*params)

        expect(note.author_id).to eq(User.llm_bot.id)
      end

      it "creates a new note associated with the provided MR" do
        note = worker.perform(*params)

        expect(note.noteable_type).to eq("MergeRequest")
        expect(note.noteable_id).to eq(merge_request.id)
      end

      it "creates a new note with the LLM attribution trailer" do
        note = worker.perform(*params)

        expect(note.note)
          .to include(
            "(AI-generated summary for revision #{merge_request.diff_head_sha})"
          )
      end
    end
  end

  context 'when type is prepare_diff_summary' do
    let(:params) do
      [user.id,
        { type: ::MergeRequests::Llm::SummarizeMergeRequestWorker::PREPARE_DIFF_SUMMARY,
          diff_id: merge_request.merge_request_diff.id }]
    end

    it 'creates a diff llm summary' do
      expect { worker.perform(*params) }.to change { ::MergeRequest::DiffLlmSummary.count }.by(1)

      expect(::MergeRequest::DiffLlmSummary.last)
        .to have_attributes(
          merge_request_diff: merge_request.merge_request_diff,
          content: message,
          provider: 'open_ai')
    end

    context 'when the diff does not exist' do
      let(:params) do
        [user.id,
          { type: ::MergeRequests::Llm::SummarizeMergeRequestWorker::PREPARE_DIFF_SUMMARY,
            diff_id: non_existing_record_id }]
      end

      it 'does not create a diff llm summary' do
        expect { worker.perform(*params) }.not_to change { ::MergeRequest::DiffLlmSummary.count }
      end
    end
  end
end
