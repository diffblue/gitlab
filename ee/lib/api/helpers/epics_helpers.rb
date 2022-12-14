# frozen_string_literal: true

module API
  module Helpers
    module EpicsHelpers
      def authorize_epics_feature!
        forbidden! unless user_group.licensed_feature_available?(:epics)
      end

      def authorize_related_epics_feature!
        forbidden! unless user_group.licensed_feature_available?(:related_epics)
      end

      def authorize_can_read!
        authorize!(:read_epic, epic)
      end

      def authorize_admin_epic_tree_relation!
        authorize!(:admin_epic_tree_relation, epic)
      end

      def authorize_can_admin_epic!
        authorize!(:admin_epic, epic)
      end

      def authorize_can_create!
        authorize!(:admin_epic, user_group)
      end

      def authorize_can_destroy!
        authorize!(:destroy_epic, epic)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def epic
        @epic ||= user_group.epics.find_by(iid: params[:epic_iid])
      end

      def find_epics(finder_params: {}, preload: nil, children_only: false)
        args = declared_params.merge(finder_params)
        args[:label_name] = args.delete(:labels)
        args[:not] ||= {}
        args[:not][:label_name] ||= args[:not].delete(:labels)

        finder_class = children_only ? ::Epics::CrossHierarchyChildrenFinder : EpicsFinder
        epics = finder_class.new(current_user, args).execute.preload(preload)

        if args[:order_by] && args[:sort]
          epics.reorder(args[:order_by] => args[:sort])
        else
          epics
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def epic_options(entity: EE::API::Entities::Epic, issuable_metadata: nil)
        {
          with: entity,
          user: current_user,
          group: user_group,
          issuable_metadata: issuable_metadata
        }
      end
    end
  end
end
