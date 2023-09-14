# frozen_string_literal: true

module Geo
  class ProjectRepositoryRegistry < Geo::BaseRegistry
    include IgnorableColumns
    include ::Geo::ReplicableRegistry
    include ::Geo::VerifiableRegistry

    MODEL_CLASS = ::Project
    MODEL_FOREIGN_KEY = :project_id

    ignore_column :force_to_redownload, remove_with: '16.4', remove_after: '2023-08-22'

    belongs_to :project, class_name: 'Project'

    # @return [Boolean] whether the project repository is out-of-date on this site
    def self.repository_out_of_date?(project_id)
      return false unless ::Gitlab::Geo.secondary_with_primary?

      registry = find_by(project_id: project_id)

      # Out-of-date if registry or project don't exist
      return true if registry.nil? || registry.project.nil?

      # Out-of-date if sync failed
      return true if registry.failed?

      # Up-to-date if there is no timestamp for the latest change to the repo
      return false unless registry.project.last_repository_updated_at

      # Out-of-date if the repo has never been synced
      return true unless registry.last_synced_at

      # Return whether the latest change is replicated
      #
      # Current limitations:
      #
      # - We assume last_repository_updated_at is a timestamp of the latest change
      # - last_repository_updated_at is also touched when a project wiki is updated
      # - last_repository_updated_at touches are throttled within Event::REPOSITORY_UPDATED_AT_INTERVAL minutes
      last_updated_at = registry.project.repository_state&.last_repository_updated_at
      last_updated_at ||= registry.project.last_repository_updated_at
      last_synced_at = registry.last_synced_at

      last_synced_at <= last_updated_at
    end
  end
end
