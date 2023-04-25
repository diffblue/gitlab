# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Completions::SummarizeAllOpenNotes, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  let(:template_class) { ::Gitlab::Llm::OpenAi::Templates::SummarizeAllOpenNotes }
  let(:ai_options) do
    {
      messages: [
        { role: "system", content: "You are a helpful assistant that summarizes comments in markdown format." },
        { role: "user", content: "Some content" }
      ],
      temperature: 0.2
    }
  end

  let(:ai_response) do
    {
      choices: [
        {
          message: {
            content: "some ai response text"
          }
        }
      ]
    }.to_json
  end

  RSpec.shared_examples 'performs completion' do
    it 'gets the right template options and calls the openai client' do
      expect_next_instance_of(::Gitlab::Llm::OpenAi::Completions::SummarizeAllOpenNotes) do |completion_service|
        expect(completion_service).to receive(:execute).with(user, issuable).and_call_original
      end

      expect(Gitlab::Llm::OpenAi::Templates::SummarizeAllOpenNotes).to receive(:get_options)
        .with(notes.pluck(:note).join("\n")).and_return(ai_options)

      expect_next_instance_of(Gitlab::Llm::OpenAi::Client) do |instance|
        expect(instance).to receive(:chat).with(content: nil, **ai_options).and_return(ai_response)
      end

      params = [user, issuable, ai_response, { options: {} }]
      response_service = double

      expect(::Gitlab::Llm::OpenAi::ResponseService).to receive(:new).with(*params).and_return(response_service)
      expect(response_service).to receive(:execute).with(an_instance_of(Gitlab::Llm::OpenAi::ResponseModifiers::Chat))

      summarize_comments
    end
  end

  subject(:summarize_comments) { described_class.new(template_class).execute(user, issuable) }

  describe "#execute" do
    context 'with invalid params' do
      context 'without user' do
        let(:user) { nil }
        let_it_be(:issuable) { double }

        specify { expect(summarize_comments).to be_nil }
      end

      context 'without issuable' do
        let_it_be(:issuable) { nil }

        specify { expect(summarize_comments).to be_nil }
      end

      context 'with invalid prompt class' do
        let_it_be(:issuable) { create(:issue, project: project) }
        let_it_be(:notes) { create_pair(:note_on_issue, project: project, noteable: issuable) }

        let(:template_class) { Issue }

        specify { expect { summarize_comments }.to raise_error(NoMethodError) }
      end
    end

    context 'with valid params' do
      context 'for an issue' do
        let_it_be(:issuable) { create(:issue, project: project) }
        let_it_be(:notes) { create_pair(:note_on_issue, project: project, noteable: issuable) }

        it_behaves_like 'performs completion'
      end

      context 'for a work item' do
        let_it_be(:issuable) { create(:work_item, :task, project: project) }
        let_it_be(:notes) { create_pair(:note_on_work_item, project: project, noteable: issuable) }

        it_behaves_like 'performs completion'
      end

      context 'for a merge request' do
        let_it_be(:issuable) { create(:merge_request, source_project: project) }
        let_it_be(:notes) { create_pair(:note_on_merge_request, project: project, noteable: issuable) }

        it_behaves_like 'performs completion'
      end

      context 'for an epic' do
        let_it_be(:issuable) { create(:epic) }
        let_it_be(:notes) { create_pair(:note_on_epic, project: project, noteable: issuable) }

        it_behaves_like 'performs completion'
      end
    end
  end
end
