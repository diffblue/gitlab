# frozen_string_literal: true

module EE
  module API
    module Snippets
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          override :find_snippets
          def find_snippets(user: current_user, params: {})
            params.delete(:repository_storage) unless can?(current_user, :change_repository_storage)

            super(user: user, params: params)
          end
        end
      end
    end
  end
end
