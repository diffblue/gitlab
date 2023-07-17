# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Templates::GenerateTestFile, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { create(:merge_request) }

  let(:path) { "files/js/commit.coffee" }

  subject { described_class.new(merge_request, path) }

  describe '.get_options' do
    it 'returns correct parameters' do
      expect(subject.to_prompt).to include("class Commit")
      expect(subject.to_prompt).to include("Write unit tests for #{path} to ensure its proper functioning")
      expect(subject.to_prompt).to include("but only if the file contains code")
    end
  end
end
