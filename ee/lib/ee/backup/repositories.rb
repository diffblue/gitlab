# frozen_string_literal: true

module EE
  module Backup
    module Repositories
      extend ::Gitlab::Utils::Override

      private

      override :repository_storage_klasses
      def repository_storage_klasses
        super << GroupWikiRepository
      end

      def group_relation
        ::Group.includes(:route, :owners, group_wiki_repository: :shard) # rubocop: disable CodeReuse/ActiveRecord
      end

      def find_groups_in_batches(&block)
        group_relation.find_each(batch_size: 1000) do |group| # rubocop: disable CodeReuse/ActiveRecord
          yield(group)
        end
      end

      override :enqueue_container
      def enqueue_container(container)
        if container.is_a?(Group)
          enqueue_group(container)
        else
          super
        end
      end

      def enqueue_group(group)
        strategy.enqueue(group, ::Gitlab::GlRepository::WIKI)
      end

      override :enqueue_consecutive
      def enqueue_consecutive
        enqueue_consecutive_groups

        super
      end

      def enqueue_consecutive_groups
        find_groups_in_batches do |group|
          enqueue_group(group)
        end
      end

      override :records_to_enqueue
      def records_to_enqueue(storage)
        super << groups_in_storage(storage)
      end

      def groups_in_storage(storage)
        group_relation.id_in(GroupWikiRepository.for_repository_storage(storage).select(:group_id))
      end
    end
  end
end
