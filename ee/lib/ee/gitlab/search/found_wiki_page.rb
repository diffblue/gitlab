# frozen_string_literal: true

module EE
  module Gitlab
    module Search
      module FoundWikiPage
        extend ::Gitlab::Utils::Override
        attr_reader :wiki

        # @param found_blob [Gitlab::Search::FoundBlob]
        override :initialize
        def initialize(found_blob)
          @wiki = found_blob.group.wiki if found_blob.group_level_blob
          super
        end
      end
    end
  end
end
