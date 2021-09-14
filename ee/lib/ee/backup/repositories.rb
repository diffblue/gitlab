# frozen_string_literal: true

module EE
  module Backup
    module Repositories
      extend ::Gitlab::Utils::Override

      private

      def group_relation
        ::Group.includes(:route, :owners, group_wiki_repository: :shard) # rubocop: disable CodeReuse/ActiveRecord
      end

      def find_groups_in_batches(&block)
        group_relation.find_each(batch_size: 1000) do |group| # rubocop: disable CodeReuse/ActiveRecord
          yield(group)
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
    end
  end
end
