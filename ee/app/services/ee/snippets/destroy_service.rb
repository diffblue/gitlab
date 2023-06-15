# frozen_string_literal: true

module EE
  module Snippets
    module DestroyService
      extend ActiveSupport::Concern

      def attempt_destroy!
        super

        snippet.snippet_repository.geo_handle_after_destroy if snippet.snippet_repository
      end
    end
  end
end
