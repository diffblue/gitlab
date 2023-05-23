# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Llm::OpenAi::Templates::SummarizeReview, feature_category: :code_review_workflow do
  let(:additional_text) { "Some message content" }

  describe ".get_options" do
    it "returns correct parameters" do
      expect(described_class.get_options(additional_text)).to eq(
        {
          messages:
          [
            {
              role: "system",
              content: described_class::SYSTEM_CONTENT
            },
            {
              role: "user",
              content: "#{described_class::DRAFT_NOTE_CONTEXT}\n\n#{additional_text}"
            }
          ],
          temperature: 0.2
        }
      )
    end
  end
end
