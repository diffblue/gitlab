# frozen_string_literal: true

module RemoteDevelopment
  class WorkspacesFinder < UnionFinder
    attr_reader :current_user, :params

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      return Workspace.none unless current_user&.can?(:read_workspace)

      items = current_user.workspaces
      items = by_ids(items)

      items.order_by('id_desc')
    end

    private

    def by_ids(items)
      return items unless params[:ids].present?

      items.id_in(params[:ids])
    end
  end
end
