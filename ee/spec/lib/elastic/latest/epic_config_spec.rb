# frozen_string_literal: true

require 'spec_helper'
require_relative './config_shared_examples'

RSpec.describe Elastic::Latest::EpicConfig, feature_category: :global_search do
  describe '.settings' do
    it_behaves_like 'config settings return correct values'
  end

  describe '.mappings' do
    it 'returns config' do
      expect(described_class.mapping).to be_a(Elasticsearch::Model::Indexing::Mappings)
    end
  end

  describe '.index_name' do
    it 'includes' do
      expect(described_class.index_name).to include('-epics')
    end
  end
end
