# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GemExtensions::Elasticsearch::Model::Indexing::InstanceMethods,
  feature_category: :global_search do
  describe '#index_document' do
    let_it_be(:project) { create(:project) }

    it 'overrides _id' do
      proxy = Elastic::Latest::ProjectInstanceProxy.new(project)

      expect(proxy.client).to receive(:index).with(
        {
          index: 'gitlab-test',
          id: "project_#{project.id}",
          body: proxy.as_indexed_json
        }
      )

      proxy.index_document
    end
  end
end
