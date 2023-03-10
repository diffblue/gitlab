# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::SnippetRepositoryReplicator, feature_category: :geo_replication do
  let(:snippet) { create(:snippet, :repository) }
  let(:model_record) { snippet.snippet_repository }

  include_examples 'a repository replicator'
  it_behaves_like 'a verifiable replicator'

  describe '.no_repo_message' do
    it 'returns the proper error message for snippet repositories' do
      expect(replicator.class.no_repo_message).to eq(::Gitlab::GitAccessSnippet.error_message(:no_repo))
    end
  end
end
