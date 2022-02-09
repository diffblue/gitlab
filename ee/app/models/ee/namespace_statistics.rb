# frozen_string_literal: true

module EE
  module NamespaceStatistics
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    def update_storage_size
      super

      self.storage_size += wiki_size
    end

    def update_wiki_size
      return unless group_wiki_available?

      self.wiki_size = namespace.wiki.repository.size.megabytes
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      override :columns_to_refresh
      def columns_to_refresh
        super << :wiki_size
      end
    end

    private

    def group_wiki_available?
      group_namespace? && namespace.licensed_feature_available?(:group_wikis)
    end
  end
end
