# frozen_string_literal: true

module Geo
  class SnippetRepositoryReplicator < Gitlab::Geo::Replicator
    include ::Geo::RepositoryReplicatorStrategy
    extend ::Gitlab::Utils::Override

    def self.model
      ::SnippetRepository
    end

    def self.git_access_class
      ::Gitlab::GitAccessSnippet
    end

    def self.no_repo_message
      git_access_class.error_message(:no_repo)
    end

    override :verification_feature_flag_enabled?
    def self.verification_feature_flag_enabled?
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
