# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::ResponseModifiers::TanukiBot, feature_category: :global_search do
  let(:ai_response) { { choices: [{ text: "#{text} ATTRS: CNT-IDX-123" }] } }
  let(:text) { 'some ai response text' }

  subject { described_class.new.execute(ai_response) }

  it 'parses content from the ai response' do
    record = create(:tanuki_bot_mvc, id: 123)

    response = {
      msg: text,
      sources: [record.metadata]
    }

    expect(subject).to eq(response)
  end

  context "when the ids don't match any documents" do
    it 'sets sources as empty' do
      response = {
        msg: text,
        sources: []
      }

      expect(subject).to eq(response)
    end
  end
end
