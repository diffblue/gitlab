# frozen_string_literal: true

module Boards
  class EpicBoardsFinder
    attr_reader :group, :params

    def initialize(group, params = {})
      @group = group
      @params = params
    end

    def execute
      relation = init_relation
      relation = by_id(relation)

      relation.order_by_name_asc
    end

    private

    def init_relation
      return group.epic_boards unless params[:include_ancestor_groups]

      ::Boards::EpicBoard.for_groups(group.self_and_ancestors)
    end

    def by_id(relation)
      return relation unless params[:id].present?

      relation.id_in(params[:id])
    end
  end
end
