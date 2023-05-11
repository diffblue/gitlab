# frozen_string_literal: true

module EE
  module Users
    module BannedUser
      extend ActiveSupport::Concern

      prepended do
        after_commit :reindex_issues_and_merge_requests, on: [:create, :destroy]
      end

      private

      def reindex_issues_and_merge_requests
        associations = [:issues]

        if ::Elastic::DataMigrationService.migration_has_finished?(:add_hidden_to_merge_requests)
          associations << :merge_requests
        end

        ElasticAssociationIndexerWorker.perform_async(user.class.name, user.id, associations)
      end
    end
  end
end
