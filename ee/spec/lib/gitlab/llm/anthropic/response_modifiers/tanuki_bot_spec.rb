# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Anthropic::ResponseModifiers::TanukiBot, feature_category: :duo_chat do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:current_user) { create(:user) }
  let_it_be(:openai_record) { create(:tanuki_bot_mvc) }
  let_it_be(:vertex_embedding) { create(:vertex_gitlab_documentation) }

  where(:use_embeddings_with_vertex, :embedding) do
    true  | ref(:vertex_embedding)
    false | ref(:openai_record)
  end

  with_them do
    let(:text) { 'some ai response text' }
    let(:ai_response) { { completion: "#{text} ATTRS: CNT-IDX-#{record_id}" }.to_json }
    let(:record_id) { embedding.id }

    before do
      stub_feature_flags(use_embeddings_with_vertex: use_embeddings_with_vertex)
    end

    describe '#response_body' do
      let(:expected_response) { text }

      subject { described_class.new(ai_response, current_user).response_body }

      it { is_expected.to eq(text) }
    end

    describe '#extras' do
      subject { described_class.new(ai_response, current_user).extras }

      context 'when the ids match existing documents' do
        let(:sources) { [embedding.metadata.merge(source_url: embedding.url)] }

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
end
