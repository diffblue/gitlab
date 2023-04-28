# frozen_string_literal: true

module Groups
  module Memberships
    class ExportService < ::BaseContainerService
      def execute
        return ServiceResponse.error(message: 'Not available') unless current_user.can?(:export_group_memberships, container)

        ServiceResponse.success(payload: csv_builder.render)
      end

      private

      def csv_builder
        @csv_builder ||= CsvBuilder.new(data, header_to_value_hash)
      end

      def data
        GroupMembersFinder.new(container, current_user).execute(include_relations: [:descendants, :direct, :inherited])
      end

      def header_to_value_hash
        {
          'Username' => -> (member) { member&.user&.username },
          'Name' => -> (member) { member&.user&.name },
          'Access granted' => -> (member) { member.created_at.to_s(:csv) },
          'Access expires' => -> (member) { member.expires_at },
          'Max role' => 'human_access',
          'Source' => -> (member) { member_source(member) }
        }
      end

      def member_source(member)
        return 'Direct member' if member.source == container
        return 'Inherited member' if container.ancestor_ids.include?(member.source_id)

        'Descendant member'
      end
    end
  end
end
