# frozen_string_literal: true

module Boards
  module Epics
    class CreateService < Boards::BaseService
      def initialize(parent, user, params = {})
        @group = parent

        super(parent, user, params)
      end

      def execute
        return ServiceResponse.error(message: 'This feature is not available') unless available?
        return ServiceResponse.error(message: Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR) unless allowed?

        error = check_arguments
        if error
          return ServiceResponse.error(message: error)
        end

        epic = ::Epics::CreateService.new(group: group, current_user: current_user, params: params.merge(epic_params)).execute

        return ServiceResponse.success(payload: epic) if epic.persisted?

        ServiceResponse.error(message: epic.errors.full_messages.join(", "))
      end

      private

      alias_method :group, :parent

      def epic_params
        { label_ids: [list.label_id] }
      end

      def board
        @board ||= Boards::EpicBoardsFinder
          .new(group, include_ancestor_groups: true, id: params.delete(:board_id))
          .execute
          .first
      end

      def list
        @list ||= board.lists.find(params.delete(:list_id))
      end

      def available?
        group.licensed_feature_available?(:epics)
      end

      def allowed?
        Ability.allowed?(current_user, :create_epic, group)
      end

      def check_arguments
        unless board && Ability.allowed?(current_user, :read_epic_board, board)
          return 'Board not found'
        end

        begin
          list
        rescue ActiveRecord::RecordNotFound
          return 'List not found' if @list.blank?
        end

        nil
      end
    end
  end
end
