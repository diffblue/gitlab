# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Completions::Chat, feature_category: :shared do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:resource) { create(:issue, project: project) }

  let(:expected_container) { group }
  let(:content) { 'Summarize issue' }
  let(:ai_request) { instance_double(Gitlab::Llm::Chain::Requests::Anthropic) }
  let(:context) { instance_double(Gitlab::Llm::Chain::GitlabContext) }
  let(:options) { { request_id: 'uuid', content: content } }
  let(:container) { group }
  let(:answer) do
    ::Gitlab::Llm::Chain::Answer.new(
      status: :ok, context: context, content: content, tool: nil, is_final: true
    )
  end

  subject { described_class.new(nil).execute(user, resource, options) }

  shared_examples 'success' do
    it 'calls the ZeroShot Agent with the right parameters' do
      tools = [
        ::Gitlab::Llm::Chain::Tools::IssueIdentifier,
        ::Gitlab::Llm::Chain::Tools::JsonReader,
        ::Gitlab::Llm::Chain::Tools::GitlabDocumentation
      ]
      expected_params = [
        user_input: content,
        tools: match_array(tools),
        context: context
      ]

      expect_next_instance_of(::Gitlab::Llm::Chain::Agents::ZeroShot::Executor, *expected_params) do |instance|
        expect(instance).to receive(:execute).and_return(answer)
      end

      expect(::Gitlab::Llm::Chain::GitlabContext).to receive(:new)
        .with(current_user: user, container: expected_container, resource: resource, ai_request: ai_request)
        .and_return(context)

      subject
    end
  end

  describe '#execute' do
    before do
      allow(Gitlab::Llm::Chain::Requests::Anthropic).to receive(:new).and_return(ai_request)
    end

    context 'when resource is an issue' do
      it_behaves_like 'success'
    end

    context 'when resource is a user' do
      let(:container) { nil }
      let(:expected_container) { nil }
      let_it_be(:resource) { user }

      it_behaves_like 'success'
    end

    context 'when resource is nil' do
      let(:resource) { nil }
      let(:expected_container) { nil }

      it_behaves_like 'success'
    end
  end
end
