# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Templates::SummarizeAllOpenNotes, feature_category: :team_planning do
  let_it_be(:issuable) { create(:issue) }

  let(:content) { "some random content" }
  let(:template) do
    "You are an assistant that extracts the most important information from the comments in maximum 10 bullet points."
  end

  subject { described_class.get_options(content) }

  describe '.get_options' do
    it 'returns correct parameters' do
      expect(subject[:content]).to include(template)
    end
  end
end
