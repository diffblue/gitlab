# frozen_string_literal: true

module Elastic
  class NamespaceUpdateWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :sticky
    feature_category :global_search

    def perform(id)
      return unless Gitlab::CurrentSettings.elasticsearch_indexing?

      namespace = Namespace.find(id)
      update_users_through_membership(namespace)
    end

    def update_users_through_membership(namespace)
      user_ids = case namespace.type
                 when 'Group'
                   group_and_descendants_user_ids(namespace)
                 when 'Project'
                   project_user_ids(namespace)
                 end

      return unless user_ids

      # rubocop:disable CodeReuse/ActiveRecord
      User.where(id: user_ids).find_in_batches do |batch_of_users|
        Elastic::ProcessBookkeepingService.track!(*batch_of_users)
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end

    def group_and_descendants_user_ids(namespace)
      namespace.self_and_descendants.flat_map(&:user_ids)
    end

    def project_user_ids(namespace)
      project = namespace.project
      project.user_ids
    end
  end
end
