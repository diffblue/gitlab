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
  end
end
