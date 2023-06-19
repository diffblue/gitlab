# frozen_string_literal: true

module EE
  module Git
    module WikiPushService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        super

        if (::Feature.disabled?(:maintain_group_wiki_index, wiki.container) || !::Wiki.use_separate_indices?) &&
            wiki.is_a?(::GroupWiki)
          return
        end

        return unless wiki.container.use_elasticsearch? && default_branch_changes.any?

        wiki.index_wiki_blobs
      end
    end
  end
end
