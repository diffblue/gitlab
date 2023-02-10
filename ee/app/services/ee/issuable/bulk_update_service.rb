# frozen_string_literal: true

module EE
  module Issuable
    module BulkUpdateService
      extend ::Gitlab::Utils::Override

      private

      override :find_issuables
      def find_issuables(parent, model_class, ids)
        return super unless model_class == ::Epic

        model_class
          .id_in(ids)
          .in_selected_groups(parent.self_and_descendants)
          .includes_for_bulk_update
      end

      override :permitted_attrs
      def permitted_attrs(type)
        return super unless type == 'issue'

        super.push(:health_status, :epic_id, :sprint_id)
      end

      override :set_update_params
      def set_update_params(type)
        super

        set_health_status
        set_epic_param
      end

      def set_health_status
        return unless params[:health_status].present?

        params[:health_status] = nil if params[:health_status] == IssuableFinder::Params::NONE.to_s
      end

      def set_epic_param
        return unless params[:epic_id].present?

        epic_id = params.delete(:epic_id)
        params[:epic] = find_epic(epic_id)
      end

      def find_epic(epic_id)
        return if remove_epic?(epic_id)

        EpicsFinder.new(current_user, group_id: group&.id, include_ancestor_groups: true).find(epic_id)
      rescue ActiveRecord::RecordNotFound
        raise ArgumentError, _('Epic not found for given params')
      end

      def remove_epic?(epic_id)
        epic_id == IssuableFinder::Params::NONE.to_s
      end

      def epics_available?
        group&.feature_available?(:epics)
      end

      def group
        parent.is_a?(Group) ? parent : parent.group
      end
    end
  end
end
