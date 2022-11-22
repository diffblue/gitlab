# frozen_string_literal: true

module Geo
  class GroupWikiRepositoryReplicator < Gitlab::Geo::Replicator
    include ::Geo::RepositoryReplicatorStrategy
    extend ::Gitlab::Utils::Override

    def self.model
      ::GroupWikiRepository
    end

    def self.git_access_class
      ::Gitlab::GitAccessWiki
    end

    def self.no_repo_message
      git_access_class.error_message(:no_group_repo)
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
