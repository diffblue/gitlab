# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module PopulateNamespaceStatistics
        extend ::Gitlab::Utils::Override

        private

        override :relation
        def relation(group_ids)
          ::Group.includes(:route, :namespace_statistics, group_wiki_repository: :shard).where(id: group_ids)
        end
      end
    end
  end
end
