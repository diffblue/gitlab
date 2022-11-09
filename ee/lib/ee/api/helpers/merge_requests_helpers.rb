# frozen_string_literal: true

module EE
  module API
    module Helpers
      module MergeRequestsHelpers
        extend ActiveSupport::Concern

        prepended do
          params :ee_approval_params do
            optional :approval_password,
              type: String,
              desc: 'Current user\'s password if project is set to require explicit auth on approval',
              documentation: { example: 'secret' }
          end
        end
      end
    end
  end
end
