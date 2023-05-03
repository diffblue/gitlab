# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Templates::GenerateDescription, feature_category: :team_planning do
  let_it_be(:issuable) { create(:issue) }

  let(:content) { "some random content" }
  let(:template) do
    "Create a markdown header with main text idea followed by a summary of the following text, in at most 10 bullet"
  end

  subject { described_class.get_options(content) }

  describe '.get_options' do
    it 'returns correct parameters' do
      expect(subject[:messages]).to include({ role: "user", content: content })
    end
  end
end
