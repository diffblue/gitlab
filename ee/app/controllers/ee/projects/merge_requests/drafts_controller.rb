# frozen_string_literal: true

module EE
  module Projects
    module MergeRequests
      module DraftsController
        extend ActiveSupport::Concern

        private

        def approve_params
          super.merge(params.permit(:approval_password))
        end
      end
    end
  end
end
