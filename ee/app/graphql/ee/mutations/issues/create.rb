# frozen_string_literal: true

module EE
  module Mutations
    module Issues
      module Create
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          include ::Mutations::Issues::CommonEEMutationArguments

          argument :epic_id, ::Types::GlobalIDType[::Epic],
                   required: false,
                   description: 'ID of an epic to associate the issue with.'
        end

        override :resolve
        def resolve(**args)
          super
        rescue ActiveRecord::RecordNotFound => e
          { errors: [e.message], issue: nil }
        end

        private

        override :build_create_issue_params
        def build_create_issue_params(params)
          # TODO: remove this line when the compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          params[:epic_id] = ::Types::GlobalIDType[::Epic].coerce_isolated_input(params[:epic_id]) if params[:epic_id]
          params[:epic_id] = params[:epic_id]&.model_id if params.key?(:epic_id)

          super(params)
        end
      end
    end
  end
end
