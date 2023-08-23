# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Embeddings::Utils::DocsContentParser, feature_category: :duo_chat do
  let(:parser) { double }

  describe '#parse_and_split' do
    let(:content) { 'Something to split' }
    let(:source_name) { '/doc/path/to/file.md' }
    let(:source_type) { 'doc' }

    subject(:parse_and_split) { described_class.parse_and_split(content, source_name, source_type) }

    it 'calls parse_and_split instance method' do
      expect(described_class).to receive(:new).and_return(parser)
      expect(parser).to receive(:parse_and_split).with(content, source_name, source_type)

      parse_and_split
    end
  end
end
