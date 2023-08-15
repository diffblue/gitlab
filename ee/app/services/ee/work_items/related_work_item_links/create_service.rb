# frozen_string_literal: true

module EE
  module WorkItems
    module RelatedWorkItemLinks
      module CreateService
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        def execute
          if params[:link_type].present? && !link_type_available?
            return error(_('Blocked work items are not available for the current subscription tier'), 403)
          end

          super
        end

        private

        def link_type_available?
          return true unless [link_class::TYPE_BLOCKS, link_class::TYPE_IS_BLOCKED_BY].include?(params[:link_type])

          issuable.resource_parent.licensed_feature_available?(:blocked_work_items)
        end

        override :linked_ids
        def linked_ids(created_links)
          return super unless params[:link_type] == 'is_blocked_by'

          created_links.collect(&:source_id)
        end
      end
    end
  end
end
