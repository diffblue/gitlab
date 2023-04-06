# frozen_string_literal: true

module Geo
  class ProjectWikiRepositoryReplicator < Gitlab::Geo::Replicator
    include ::Geo::RepositoryReplicatorStrategy
    extend ::Gitlab::Utils::Override

    def self.model
      ::Projects::WikiRepository
    end

    def self.git_access_class
      ::Gitlab::GitAccessWiki
    end

    def self.no_repo_message
      git_access_class.error_message(:no_repo)
    end

    override :verification_feature_flag_enabled?
    def self.verification_feature_flag_enabled?
      # We are adding verification at the same time as replication, so we
      # don't need to toggle verification separately from replication. When
      # the replication feature flag is off, then verification is also off
      # (see `VerifiableReplicator.verification_enabled?`)
      true
    end

    override :housekeeping_model_record
    def housekeeping_model_record
      # The Repositories::HousekeepingService and Wikis::GitGarbageCollectWorker
      # still rely on an instance of Wiki being the resource. We can remove this
      # when we update both to rely on the Projects::WikiRepository model.
      model_record.wiki
    end

    override :snapshot_enabled?
    def snapshot_enabled?
      true
    end

    override :snapshot_url
    def snapshot_url
      ::Gitlab::Geo.primary_node.api_url("projects/#{model_record.project.id}/snapshot?wiki=1")
    end

    def repository
      model_record.repository
    end
  end
end
