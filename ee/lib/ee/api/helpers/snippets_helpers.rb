# frozen_string_literal: true

module EE
  module API
    module Helpers
      module SnippetsHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_list_params_ee do
            optional :repository_storage, type: String, desc: 'Filter by repository storage used by the snippet'
          end
        end
      end
    end
  end
end
