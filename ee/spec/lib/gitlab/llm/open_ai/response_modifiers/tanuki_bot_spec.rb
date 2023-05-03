# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::ResponseModifiers::TanukiBot, feature_category: :global_search do
  let(:ai_response) { { choices: [{ text: "#{text} ATTRS: CNT-IDX-#{record_id}" }] } }
  let(:text) { 'some ai response text' }
  let(:response) { { msg: text, sources: sources }.with_indifferent_access }

  subject { ::Gitlab::Json.parse(described_class.new.execute(ai_response)) }

  context 'when the ids match existing documents' do
    let(:record) { create(:tanuki_bot_mvc) }
    let(:record_id) { record.id }
    let(:sources) { [record.metadata.merge(source_url: record.url)] }

    it 'parses content from the ai response and populates source_url into metadata' do
      expect(subject).to match(response)
    end
  end

  context "when the ids don't match any documents" do
    let(:record_id) { non_existing_record_id }
    let(:sources) { [] }

    it 'sets sources as empty' do
      expect(subject).to match(response)
    end
  end

  context "when the message contains the text I don't know" do
    let(:text) { "I don't know the answer to your question" }
    let(:record_id) { non_existing_record_id }
    let(:sources) { [] }

    it 'sets sources as empty' do
      expect(subject).to match(response)
    end
  end
end
