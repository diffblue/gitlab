# frozen_string_literal: true

module EE
  module QuickActions
    module TargetService
      def execute(type, type_iid)
        return epic(type_iid) if type&.casecmp('epic') == 0

        super
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def epic(type_iid)
        group = params[:group]

        return group.epics.build if type_iid.nil?

        EpicsFinder.new(current_user, group_id: group.id).find_by(iid: type_iid) || group.epics.build
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
