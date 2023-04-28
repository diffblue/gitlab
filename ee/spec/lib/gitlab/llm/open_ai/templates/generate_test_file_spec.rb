# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::OpenAi::Templates::GenerateTestFile, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { create(:merge_request) }

  let(:path) { "files/js/commit.coffee" }

  subject { described_class.get_options(merge_request, path) }

  describe '.get_options' do
    it 'returns correct parameters' do
      expect(subject[:content]).to include("class Commit")
      expect(subject[:content]).to include("Write unit tests for #{path} to ensure its proper functioning")
      expect(subject[:content]).to include("but only if the file contains code")
      expect(subject[:temperature]).to eq(0.2)
    end
  end
end
