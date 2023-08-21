# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Utils::Prompt, feature_category: :duo_chat do
  let(:content) { ["multi", "line", "%<message>s"] }

  describe 'messages with roles' do
    it 'returns message as system' do
      expect(described_class.as_system(content)).to eq([:system, "multi\nline\n%<message>s"])
    end

    it 'returns message as assistant' do
      expect(described_class.as_assistant(content)).to eq([:assistant, "multi\nline\n%<message>s"])
    end

    it 'returns message as user' do
      expect(described_class.as_user(content)).to eq([:user, "multi\nline\n%<message>s"])
    end
  end

  describe '#no_role_text' do
    let(:prompt) { described_class.as_assistant(content) }
    let(:input_vars) { { message: 'input' } }

    it 'returns bare text from role based prompt' do
      expect(described_class.no_role_text([prompt], input_vars)).to eq("multi\nline\ninput")
    end
  end

  describe '#role_conversation' do
    let(:prompt) { described_class.as_assistant(content) }
    let(:input_vars) { { message: 'input' } }

    it 'returns bare text from role based prompt' do
      result = { role: :assistant, content: "multi\nline\ninput" }

      expect(described_class.role_conversation([prompt], input_vars)).to eq([result].to_json)
    end
  end

  describe "#default_system_prompt" do
    let(:explain_current_blob) do
      "You can explain code if the user provided a code snippet and answer directly."
    end

    it 'includes the prompt to explain code directly' do
      expect(described_class.default_system_prompt(explain_current_blob: true)).to include explain_current_blob
    end

    context 'when explain_current_blob is false by default' do
      it 'omits the prompt to explain code directly' do
        expect(described_class.default_system_prompt).to exclude explain_current_blob
      end
    end
  end
end
