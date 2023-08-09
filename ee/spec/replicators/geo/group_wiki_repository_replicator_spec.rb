# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::GroupWikiRepositoryReplicator, feature_category: :geo_replication do
  let(:model_record) { build(:group_wiki_repository, group: create(:group)) }

  include_examples 'a repository replicator' do
    def handle_model_record_before_verification_integration_examples
      model_record.save!
      model_record.repository.create_if_not_exists
    end
  end

  describe '.no_repo_message' do
    it 'returns the proper error message for group-level wikis' do
      expect(replicator.class.no_repo_message).to eq(::Gitlab::GitAccessWiki.error_message(:no_group_repo))
    end
  end
end
