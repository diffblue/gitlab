# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Agents::ZeroShot::Prompts::VertexAi, feature_category: :duo_chat do
  include FakeBlobHelpers

  describe '.prompt' do
    it 'returns prompt' do
      options = {
        tools_definitions: "tool definitions",
        tool_names: "tool names",
        user_input: 'foo?',
        agent_scratchpad: "some observation",
        prompt_version: ::Gitlab::Llm::Chain::Agents::ZeroShot::Executor::PROMPT_TEMPLATE,
        current_code: ""
      }
      prompt = described_class.prompt(options)[:prompt]
      prompt_text = "Answer the question as accurate as you can."

      expect(prompt).to include('foo?')
      expect(prompt).to include('tool definitions')
      expect(prompt).to include('tool names')
      expect(prompt).to include(prompt_text)
      expect(prompt).to include(Gitlab::Llm::Chain::Utils::Prompt.default_system_prompt)
    end
  end

  describe '.current_code_prompt' do
    let(:project) { build(:project) }
    let(:blob) { fake_blob(path: 'foobar.rb', data: 'puts "hello world"') }

    subject(:prompt) { described_class.current_code_prompt(blob) }

    it 'returns the base prompt' do
      expect(prompt).to include("The current code file that user sees is foobar.rb and")
      expect(prompt).to include("has the following content:\nputs \"hello world\"\n")
    end
  end
end
