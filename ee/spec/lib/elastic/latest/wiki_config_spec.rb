# frozen_string_literal: true

require 'spec_helper'
require_relative './config_shared_examples'

RSpec.describe Elastic::Latest::WikiConfig, feature_category: :global_search do
  describe '.settings' do
    it_behaves_like 'config settings return correct values'
  end

  describe '.mappings' do
    it 'returns config' do
      expect(described_class.mapping).to be_a(Elasticsearch::Model::Indexing::Mappings)
      expect(described_class.mapping.to_hash).to include(:dynamic, :properties)
    end
  end
end
