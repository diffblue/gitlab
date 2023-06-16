# frozen_string_literal: true

module Geo
  class DesignManagementRepositoryReplicator < Gitlab::Geo::Replicator
    include ::Geo::RepositoryReplicatorStrategy
    extend ::Gitlab::Utils::Override

    def self.model
      DesignManagement::Repository
    end

    def self.git_access_class
      ::Gitlab::GitAccessDesign
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

    override :housekeeping_enabled?
    def self.housekeeping_enabled?
      false
    end

    def repository
      model_record.repository
    end

    override :verify
    def verify
      # Git repositories for designs are not created unless a design is added
      # but DesignManagement::Repository records were added for all projects
      # regardless of an existing git repo, in a migration.
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116975
      # This results in verification failures.
      # TODO Remove empty repo creation once unnecessary DesignManagement::Repository
      # records are removed https://gitlab.com/gitlab-org/gitlab/-/issues/415551

      repository.create_if_not_exists

      super
    end
  end
end
