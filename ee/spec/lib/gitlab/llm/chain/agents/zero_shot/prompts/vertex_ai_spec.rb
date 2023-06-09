# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Agents::ZeroShot::Prompts::VertexAi, feature_category: :shared do
  describe '.prompt' do
    it 'returns prompt' do
      options = {
        tools_definitions: "tool definitions",
        tool_names: "tool names",
        user_input: 'foo?',
        agent_scratchpad: "some observation"
      }
      prompt = described_class.prompt(options)

      expect(prompt).to include('foo?')
      expect(prompt).to include('tool definitions')
      expect(prompt).to include('tool names')
      expect(prompt).to include('Answer the following questions as best you can. Start with identifying the resource')
      expect(prompt).to include(Gitlab::Llm::Chain::Utils::Prompt.default_system_prompt)
    end
  end
end
