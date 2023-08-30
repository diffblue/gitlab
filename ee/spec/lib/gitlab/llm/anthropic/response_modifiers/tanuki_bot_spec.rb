# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Anthropic::ResponseModifiers::TanukiBot, feature_category: :duo_chat do
  let(:text) { 'some ai response text' }
  let(:ai_response) { { completion: "#{text} ATTRS: CNT-IDX-#{record_id}" }.to_json }

  describe '#response_body' do
    let(:expected_response) { { content: text, sources: sources }.with_indifferent_access }
    let(:sources) { [] }

    subject { ::Gitlab::Json.parse(described_class.new(ai_response).response_body) }

    context 'when the ids match existing documents' do
      let(:record) { create(:tanuki_bot_mvc) }
      let(:record_id) { record.id }
      let(:sources) { [record.metadata.merge(source_url: record.url)] }

      it 'parses content from the ai response and populates source_url into metadata' do
        expect(subject).to match(expected_response)
      end
    end

    context "when the ids don't match any documents" do
      let(:record_id) { non_existing_record_id }

      it 'sets sources as empty' do
        expect(subject).to match(expected_response)
      end
    end

    context "when the message contains the text I don't know" do
      let(:text) { "I don't know the answer to your question" }
      let(:record_id) { non_existing_record_id }

      it 'sets sources as empty' do
        expect(subject).to match(expected_response)
      end
    end
  end

  describe '#extras' do
    subject { described_class.new(ai_response).extras }

    context 'when the ids match existing documents' do
      let(:record) { create(:tanuki_bot_mvc) }
      let(:record_id) { record.id }
      let(:sources) { [record.metadata.merge(source_url: record.url)] }

      it 'fills sources' do
        expect(subject).to eq(sources: sources)
      end
    end

    context "when the ids don't match any documents" do
      let(:record_id) { non_existing_record_id }

      it 'sets extras as empty' do
        expect(subject).to eq(sources: [])
      end
    end

    context "when the message contains the text I don't know" do
      let(:text) { "I don't know the answer to your question" }
      let(:record_id) { non_existing_record_id }

      it 'sets extras as empty' do
        expect(subject).to eq(sources: [])
      end
    end
  end
end
