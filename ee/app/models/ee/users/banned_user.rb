# frozen_string_literal: true

module EE
  module Users
    module BannedUser
      extend ActiveSupport::Concern

      prepended do
        after_commit :reindex_issues, on: [:create, :destroy], if: :add_hidden_to_issues_migration_completed?
      end

      private

      def reindex_issues
        ElasticAssociationIndexerWorker.perform_async(user.class.name, user.id, [:issues])
      end

      def add_hidden_to_issues_migration_completed?
        ::Elastic::DataMigrationService.migration_has_finished?(:add_hidden_to_issues)
      end
    end
  end
end
