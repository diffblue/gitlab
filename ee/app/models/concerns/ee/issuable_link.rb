# frozen_string_literal: true

module EE
  module IssuableLink
    extend ActiveSupport::Concern

    prepended do
      # we don't store is_blocked_by in the db but need it for displaying the relation
      # from the target
      TYPE_IS_BLOCKED_BY = 'is_blocked_by'
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      def inverse_link_type(type)
        return IssuableLink::TYPE_IS_BLOCKED_BY if type == ::IssuableLink::TYPE_BLOCKS

        super
      end

      def blocked_issuable_ids(issuable_ids)
        blocked_or_blocking_issuables(issuable_ids).pluck(:target_id)
      end

      def blocking_issuables_ids_for(issuable)
        blocked_or_blocking_issuables(issuable.id).pluck(:source_id)
      end

      def blocking_issuables_for_collection(issuables_ids)
        open_state_id = ::Issuable::STATE_ID_MAP[:opened]
        grouping_row_name = "blocking_#{issuable_type}_id"
        issuable_table_name = issuable_type.to_s.pluralize
        links_table_name = self.table_name

        select("COUNT(CASE WHEN #{issuable_table_name}.state_id = #{open_state_id} then 1 else null end), #{links_table_name}.source_id AS #{grouping_row_name}")
          .joins(:target)
          .where(link_type: self::TYPE_BLOCKS, source_id: issuables_ids)
          .group(grouping_row_name)
      end

      def blocked_issuables_for_collection(issuables_ids)
        grouping_row_name = "blocked_#{issuable_type}_id"

        select("COUNT(*), #{self.table_name}.target_id AS #{grouping_row_name}")
          .joins(:source)
          .where(source: { state_id: ::Issuable::STATE_ID_MAP[:opened] })
          .where(link_type: self::TYPE_BLOCKS)
          .where(target_id: issuables_ids)
          .group(grouping_row_name)
      end

      def blocking_issuables_count_for(issuable)
        blocking_issuables_for_collection(issuable.id)[0]&.count.to_i
      end

      override :available_link_types
      def available_link_types
        super + [::IssuableLink::TYPE_BLOCKS, ::IssuableLink::TYPE_IS_BLOCKED_BY]
      end

      private

      def blocked_or_blocking_issuables(issuables_ids)
        where(link_type: ::IssuableLink::TYPE_BLOCKS).where(target_id: issuables_ids)
          .joins(:source)
          .where(source: { state_id: ::Issuable::STATE_ID_MAP[:opened] })
      end
    end
  end
end
