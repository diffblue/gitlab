# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::ProjectWikiInstanceProxy, feature_category: :global_search do
  let_it_be(:project) { create(:project, :wiki_repo) }

  subject { described_class.new(project.wiki, use_separate_indices: true) }

  describe '#elastic_search_as_wiki_page' do
    let(:params) do
      {
        page: 2,
        per: 30,
        options: { foo: :bar }
      }
    end

    it 'provides repository_id if not provided' do
      expected_params = params.deep_dup
      expected_params[:options][:repository_id] = "wiki_#{project.id}"

      expect(subject.class).to receive(:elastic_search_as_wiki_page).with('foo', expected_params)

      subject.elastic_search_as_wiki_page('foo', **params)
    end

    it 'uses provided repository_id' do
      params[:options][:repository_id] = "wiki_63"

      expect(subject.class).to receive(:elastic_search_as_wiki_page).with('foo', params)

      subject.elastic_search_as_wiki_page('foo', **params)
    end
  end
end
