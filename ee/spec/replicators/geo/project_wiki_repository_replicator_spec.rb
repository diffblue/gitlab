# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectWikiRepositoryReplicator, feature_category: :geo_replication do
  let(:project) { create(:project, :wiki_repo, wiki_repository: build(:project_wiki_repository, project: nil)) }
  let(:model_record) { project.wiki_repository }

  include_examples 'a repository replicator' do
    let(:housekeeping_model_record) { model_record.wiki }

    describe '#snapshot_enabled?' do
      it 'returns true' do
        expect(replicator.snapshot_enabled?).to eq(true)
      end
    end

    describe '#snapshot_url' do
      it 'returns snapshot URL based on the primary node URI' do
        snapshot_url =
          Gitlab::Utils.append_path(
            primary.internal_uri.to_s,
            "/api/#{API::API.version}/projects/#{model_record.project.id}/snapshot?wiki=1"
          )

        expect(replicator.snapshot_url).to eq(snapshot_url)
      end
    end
  end

  include_examples 'a verifiable replicator'
end
