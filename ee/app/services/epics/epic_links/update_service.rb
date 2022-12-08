# frozen_string_literal: true

module Epics
  module EpicLinks
    class UpdateService < BaseService
      attr_reader :epic
      private :epic

      def initialize(epic, user, params)
        @epic = epic
        @current_user = user
        @params = params
      end

      def execute
        unless can?(current_user, :admin_epic_tree_relation, epic)
          return error('Epic not found for given params', 404)
        end

        move_epic!
        success
      rescue ActiveRecord::RecordNotFound
        error('Epic not found for given params', 404)
      end

      private

      def move_epic!
        return unless params[:move_after_id] || params[:move_before_id]

        before_epic = Epic.in_parents(epic.parent_id).find(params[:move_before_id]) if params[:move_before_id]
        after_epic = Epic.in_parents(epic.parent_id).find(params[:move_after_id]) if params[:move_after_id]

        epic.move_between(before_epic, after_epic)
        epic.save!(touch: false)
      end
    end
  end
end
