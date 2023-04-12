# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::CompletionWorker, feature_category: :team_planning do
  include AfterNextHelpers

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  describe '#perform' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:issuable) { create(:issue, project: project) }

    let(:user_id) { user.id }
    let(:issuable_id) { issuable.id }
    let(:issuable_type) { issuable.class.name }
    let(:options) { { 'key' => 'value' } }
    let(:ai_template) { { method: :completions, prompt: 'something', options: { temperature: 0.7 } } }
    let(:ai_action_name) { :summarize_comments }

    subject { described_class.new.perform(user_id, issuable_id, issuable_type, ai_action_name, options) }

    shared_examples 'performs successfully' do
      it 'calls Gitlab::Llm::OpenAi::Templates::SummarizeAllOpenNotes and Gitlab::Llm::OpenAi::Client services' do
        expect_next_instance_of(::Gitlab::Llm::OpenAi::Completions::SummarizeAllOpenNotes) do |completion_service|
          expect(completion_service).to receive(:execute).with(user, issuable, options.symbolize_keys).and_call_original
        end

        expect(Gitlab::Llm::OpenAi::Templates::SummarizeAllOpenNotes).to receive(:get_prompt).and_return(ai_template)

        allow_next_instance_of(Gitlab::Llm::OpenAi::Client) do |instance|
          allow(instance).to receive(:completions).with(prompt: 'something', max_tokens: 1000, temperature: 0.7)
        end

        subject
      end
    end

    context 'with valid parameters' do
      context 'for an issue' do
        let_it_be(:issuable) { create(:issue, project: project) }
        let_it_be(:notes) { create_pair(:note_on_issue, project: project, noteable: issuable) }

        it_behaves_like 'performs successfully'
      end

      context 'for a work item' do
        let_it_be(:issuable) { create(:work_item, :task, project: project) }
        let_it_be(:notes) { create_pair(:note_on_work_item, project: project, noteable: issuable) }

        it_behaves_like 'performs successfully'
      end

      context 'for a merge request' do
        let_it_be(:issuable) { create(:merge_request, source_project: project) }
        let_it_be(:notes) { create_pair(:note_on_merge_request, project: project, noteable: issuable) }

        it_behaves_like 'performs successfully'
      end

      context 'for an epic' do
        let_it_be(:issuable) { create(:epic) }
        let_it_be(:notes) { create_pair(:note_on_epic, project: project, noteable: issuable) }

        it_behaves_like 'performs successfully'
      end
    end

    context 'with invalid parameters' do
      context 'when issue type is not supported' do
        let(:issuable_type) { 'invalid' }

        it 'does not call Gitlab::Llm::OpenAi::Templates::Issuable' do
          expect(Gitlab::Llm::OpenAi::Templates::SummarizeAllOpenNotes).not_to receive(:get_prompt)

          expect { subject }.to raise_error(NameError, "uninitialized constant Invalid")
        end
      end

      context 'when issue is confidential' do
        let_it_be(:issuable) { create(:issue, :confidential, project: project) }

        it 'does not call Gitlab::Llm::OpenAi::Templates::Issuable' do
          expect(Gitlab::Llm::OpenAi::Templates::SummarizeAllOpenNotes).not_to receive(:get_prompt)

          subject
        end

        it { is_expected.to be_nil }
      end

      context 'when project is not public' do
        let_it_be(:project) { create(:project, :private) }
        let_it_be(:issuable) { create(:issue, project: project) }

        it 'does not call Gitlab::Llm::OpenAi::Templates::Issuable' do
          expect(Gitlab::Llm::OpenAi::Templates::SummarizeAllOpenNotes).not_to receive(:get_prompt)

          subject
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
