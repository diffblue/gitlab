# frozen_string_literal: true

module EE
  module Users
    module BannedUser
      extend ActiveSupport::Concern

      prepended do
        after_commit :reindex_issues, on: [:create, :destroy]
      end

      private

      def reindex_issues
        ElasticAssociationIndexerWorker.perform_async(user.class.name, user.id, [:issues])
      end
    end
  end
end
