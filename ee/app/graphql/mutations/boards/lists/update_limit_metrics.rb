# frozen_string_literal: true

module Mutations
  module Boards
    module Lists
      class UpdateLimitMetrics < ::Mutations::BaseMutation
        graphql_name 'BoardListUpdateLimitMetrics'

        argument :list_id,
                 ::Types::GlobalIDType[::List],
                 required: true,
                 description: 'The global ID of the list.'

        argument :limit_metric,
                 EE::Types::ListLimitMetricEnum,
                 required: false,
                 description: 'The new limit metric type for the list.'

        argument :max_issue_count,
                 GraphQL::Types::Int,
                 required: false,
                 description: 'The new maximum issue count limit.'

        argument :max_issue_weight,
                 GraphQL::Types::Int,
                 required: false,
                 description: 'The new maximum issue weight limit.'

        field :list,
              ::Types::BoardListType,
              null: true,
              description: 'The updated list.'

        def ready?(**args)
          if limit_metric_settings_of(args).blank?
            raise Gitlab::Graphql::Errors::ArgumentError,
                  'At least one of the arguments limitMetric, maxIssueCount or maxIssueWeight is required'
          end

          super
        end

        def resolve(**args)
          find_list_by_args!(args)

          update_result = update_list(args)

          {
            list: update_result.payload.fetch(:list),
            errors: update_result.errors
          }
        end

        private

        attr_reader :list

        def find_list_by_args!(args)
          @list ||= find_list_by_global_id(args[:list_id])

          raise_resource_not_available_error! unless list

          authorize_admin_rights!
        end

        def update_list(args)
          service = ::Boards::Lists::UpdateService.new(board, current_user, limit_metric_settings_of(args))
          service.execute(list)
        end

        def authorize_admin_rights!
          raise_resource_not_available_error! unless Ability.allowed?(current_user, :admin_issue_board_list, board)
        end

        def find_list_by_global_id(gid)
          return unless gid

          # TODO: remove this line when the compatibility layer is removed
          # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
          gid = ::Types::GlobalIDType[::List].coerce_isolated_input(gid)
          List.find_by_id(gid.model_id)
        end

        def board
          @board ||= list.board
        end

        def limit_metric_settings_of(args)
          args.slice(:limit_metric, :max_issue_count, :max_issue_weight)
        end
      end
    end
  end
end
