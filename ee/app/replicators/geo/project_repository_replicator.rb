# frozen_string_literal: true

module Geo
  class ProjectRepositoryReplicator < Gitlab::Geo::Replicator
    include ::Geo::RepositoryReplicatorStrategy
    extend ::Gitlab::Utils::Override

    def self.model
      ::Project
    end

    def self.git_access_class
      ::Gitlab::GitAccessProject
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

    def before_housekeeping
      return unless ::Gitlab::Geo.secondary?

      create_object_pool_on_secondary if create_object_pool_on_secondary?
    end

    def repository
      model_record.repository
    end

    private

    def pool_repository
      model_record.pool_repository
    end

    def create_object_pool_on_secondary
      Geo::CreateObjectPoolService.new(pool_repository).execute
    end

    def create_object_pool_on_secondary?
      return unless model_record.object_pool_missing?
      return unless pool_repository.source_project_repository.exists?

      true
    end
  end
end
