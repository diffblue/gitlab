# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::CompletionsFactory, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  describe ".completion" do
    context 'with existing completion' do
      let(:completion_name) { :summarize_review }

      it 'returns completion service' do
        completion_class = ::Gitlab::Llm::VertexAi::Completions::SummarizeReview
        template_class = ::Gitlab::Llm::Templates::SummarizeReview

        expect(completion_class).to receive(:new).with(template_class, {}).and_call_original

        completion = described_class.completion(completion_name)

        expect(completion).to be_a(completion_class)
      end

      it 'passes parameters to the completion class' do
        completion_class = ::Gitlab::Llm::VertexAi::Completions::ExplainVulnerability
        template_class = ::Gitlab::Llm::Templates::ExplainVulnerability

        expect(completion_class).to receive(:new).with(template_class, { include_source_code: true }).and_call_original

        completion = described_class.completion(:explain_vulnerability, { include_source_code: true })

        expect(completion).to be_a(completion_class)
      end
    end

    context 'with invalid completion' do
      let(:completion_name) { :invalid_name }

      it 'returns completion service' do
        completion = described_class.completion(completion_name)

        expect(completion).to be_nil
      end
    end
  end
end
