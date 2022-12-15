# frozen_string_literal: true

module EE
  module Packages
    module PackageFile
      extend ActiveSupport::Concern

      EE_SEARCHABLE_ATTRIBUTES = %i[file_name].freeze

      prepended do
        include ::Geo::ReplicableModel
        include ::Geo::VerifiableModel
        include ::Geo::VerificationStateDefinition
        include ::Gitlab::SQL::Pattern

        with_replicator ::Geo::PackageFileReplicator
      end

      class_methods do
        # @param primary_key_in [Range, Packages::PackageFile] arg to pass to primary_key_in scope
        # @return [ActiveRecord::Relation<LfsObject>] everything that should be synced to this node, restricted by primary key
        def replicables_for_current_secondary(primary_key_in)
          primary_key_in(primary_key_in)
            .merge(selective_sync_scope)
            .merge(object_storage_scope)
        end

        # Search for a list of package_files based on the query given in `query`.
        #
        # @param [String] query term that will search over package_file :file_name
        #
        # @return [ActiveRecord::Relation<Packages::PackageFile>] a collection of package files
        def search(query)
          return all if query.empty?

          fuzzy_search(query, EE_SEARCHABLE_ATTRIBUTES).limit(500)
        end

        private

        # @return [ActiveRecord::Relation<Packages::PackageFile>] scope observing object storage settings
        def object_storage_scope
          return self.all if ::Gitlab::Geo.current_node.sync_object_storage?

          self.with_files_stored_locally
        end

        # @return [ActiveRecord::Relation<Packages::PackageFile>] scope observing selective sync settings
        def selective_sync_scope
          return self.all unless ::Gitlab::Geo.current_node.selective_sync?

          self.joins(:package)
              .where(packages_packages: { project_id: ::Gitlab::Geo.current_node.projects.select(:id) })
        end
      end

      def log_geo_deleted_event
        # Keep empty for now. Should be addressed in future
        # by https://gitlab.com/gitlab-org/gitlab/issues/7891
      end
    end
  end
end
