# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Concerns::AiDependent, feature_category: :duo_chat do
  let(:options) { { suggestions: "", input: "" } }
  let(:ai_request) { ::Gitlab::Llm::Chain::Requests::Anthropic.new(double) }
  let(:context) do
    ::Gitlab::Llm::Chain::GitlabContext.new(
      current_user: double,
      container: double,
      resource: double,
      ai_request: ai_request
    )
  end

  describe '#prompt' do
    context 'when prompt is called' do
      it 'returns provider specific prompt' do
        tool = ::Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor.new(context: context, options: options)

        expect(tool).not_to receive(:base_prompt).and_call_original

        prompt = tool.prompt[:prompt]

        expect(prompt).to include("You can fetch information about a resource called: an issue.")
        expect(prompt).to include("Human:")
        expect(prompt).to include("Assistant:")
      end
    end

    context 'when base_prompt is implemented' do
      before do
        stub_const('::Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor::PROVIDER_PROMPT_CLASSES', {})
      end

      it 'returns base_prompt value' do
        tool = ::Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor.new(context: context, options: options)

        expect(tool).to receive(:base_prompt).and_call_original

        prompt = tool.prompt[:prompt]

        expect(prompt).to include("You can fetch information about a resource called: an issue.")
        expect(prompt).not_to include("Human:")
        expect(prompt).not_to include("Assistant:")
      end
    end

    context 'when base_prompt is not implemented' do
      let(:dummy_tool_class) do
        Class.new(::Gitlab::Llm::Chain::Tools::Tool) do
          include ::Gitlab::Llm::Chain::Concerns::AiDependent

          def provider_prompt_class
            nil
          end
        end
      end

      it 'raises error' do
        tool = dummy_tool_class.new(context: context, options: {})

        expect { tool.prompt }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#request' do
    it 'passes prompt to the ai_client' do
      tool = ::Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor.new(context: context, options: options)

      expect(ai_request).to receive(:request).with(tool.prompt)

      tool.request
    end

    it 'passes blocks forward to the ai_client' do
      b = proc { "something" }
      tool = ::Gitlab::Llm::Chain::Tools::IssueIdentifier::Executor.new(context: context, options: options)

      expect(ai_request).to receive(:request).with(tool.prompt, &b)

      tool.request(&b)
    end
  end
end
