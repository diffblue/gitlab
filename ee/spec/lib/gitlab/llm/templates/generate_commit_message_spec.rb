# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Templates::GenerateCommitMessage, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { create(:merge_request) }

  subject { described_class.new(merge_request) }

  describe '#options' do
    context 'for OpenAI' do
      let(:client) { ::Gitlab::Llm::OpenAi::Client }

      it 'returns max tokens' do
        expect(subject.options(client)).to match(hash_including({
          max_tokens: described_class::MAX_TOKENS
        }))
      end
    end

    context 'for VertexAI' do
      let(:client) { ::Gitlab::Llm::VertexAi::Client }

      it 'returns max tokens' do
        expect(subject.options(client)).to be_empty
      end
    end
  end

  describe '#to_prompt' do
    it 'includes merge request title' do
      expect(subject.to_prompt).to include(merge_request.title)
    end

    it 'includes raw diff' do
      diff_file = merge_request.raw_diffs.to_a[0]

      expect(subject.to_prompt).to include("Filename: #{diff_file.new_path}")
      expect(subject.to_prompt).to include(diff_file.diff.split("\n")[1])
    end
  end
end
