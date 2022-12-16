# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module BaseChecker
        extend ActiveSupport::Concern
        include ::Gitlab::Utils::StrongMemoize

        private

        def push_rule
          strong_memoize(:push_rule) do
            project.predefined_push_rule
          end
        end
      end
    end
  end
end
