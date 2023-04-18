# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Llm::SummarizeMergeRequestWorker, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project) { merge_request.project }
  let(:example_llm_response) do
    {
      "id" => "chatcmpl-72mX77BBH9Hgj196u7BDhKyCTiXxL",
      "object" => "chat.completion",
      "created" => 1680897573,
      "model" => "gpt-3.5-turbo-0301",
      "usage" => { "prompt_tokens" => 3447, "completion_tokens" => 57, "total_tokens" => 3504 },
      "choices" =>
        [{
          "message" => { "role" => "assistant", "content" => "An answer from an LLM" },
          "finish_reason" => "stop",
          "index" => 0
        }]
    }
  end

  let(:response_double) { instance_double(HTTParty::Response, parsed_response: example_llm_response) }

  subject(:worker) { described_class.new }

  context "when provided an invalid merge_request_id" do
    it "returns nil" do
      expect(worker.perform(non_existing_record_id, user.id)).to be_nil
    end

    it "does not create a new note" do
      expect { worker.perform(non_existing_record_id, user.id) }.not_to change { Note.count }
    end
  end

  context "when provided an invalid user_id" do
    it "returns nil" do
      expect(worker.perform(merge_request.id, non_existing_record_id)).to be_nil
    end

    it "does not create a new note" do
      expect { worker.perform(merge_request.id, non_existing_record_id) }.not_to change { Note.count }
    end
  end

  context "when user is not able to create new notes" do
    it "returns nil" do
      expect(worker.perform(merge_request.id, user.id)).to be_nil
    end

    it "does not create a new note" do
      expect { worker.perform(merge_request.id, user.id) }.not_to change { Note.count }
    end
  end

  context "when user can create new notes" do
    before do
      project.add_developer(user)

      allow_next_instance_of(Gitlab::Llm::OpenAi::Client) do |llm_client|
        allow(llm_client).to receive(:chat).and_return(response_double)
      end
    end

    it "creates a new note" do
      expect { worker.perform(merge_request.id, user.id) }
        .to change { Note.count }.by(1)
    end

    it "creates a new note by the llm_bot" do
      note = worker.perform(merge_request.id, user.id)

      expect(note.author_id).to eq(User.llm_bot.id)
    end

    it "creates a new note associated with the provided MR" do
      note = worker.perform(merge_request.id, user.id)

      expect(note.noteable_type).to eq("MergeRequest")
      expect(note.noteable_id).to eq(merge_request.id)
    end

    it "creates a new note with the LLM attribution trailer" do
      note = worker.perform(merge_request.id, user.id)

      expect(note.note)
        .to include(
          "(AI-generated summary for revision #{merge_request.diff_head_sha})"
        )
    end
  end
end
