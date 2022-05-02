# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GemExtensions::Elasticsearch::Model::Indexing::InstanceMethods do
  describe '#index_document' do
    let(:project) { Project.new(id: 1) }

    it 'overrides _id' do
      proxy = Elastic::Latest::ProjectInstanceProxy.new(project)

      expect(proxy.client).to receive(:index).with(
        {
          index: 'gitlab-test',
          id: 'project_1',
          body: proxy.as_indexed_json
        }
      )

      proxy.index_document
    end
  end
end
