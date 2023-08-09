# frozen_string_literal: true

module Preloaders
  class UserMemberRolesInGroupsPreloader
    def initialize(groups:, user:)
      @groups = if groups.is_a?(Array)
                  Group.where(id: groups)
                else
                  # Push groups base query in to a sub-select to avoid
                  # table name clashes. Performs better than aliasing.
                  Group.where(id: groups.reselect(:id))
                end

      @user = user
    end

    def execute
      sql_values_array = groups.filter_map do |group|
        next unless group.custom_roles_enabled?

        [group.id, Arel.sql("ARRAY[#{group.traversal_ids.join(',')}]::integer[]")]
      end

      return {} if sql_values_array.empty?

      value_list = Arel::Nodes::ValuesList.new(sql_values_array)

      permissions = MemberRole::ALL_CUSTOMIZABLE_GROUP_PERMISSIONS
      permission_select = permissions.map { |p| "bool_or(custom_permissions.#{p}) AS #{p}" }.join(', ')
      permission_condition = permissions.map { |p| "member_roles.#{p} = true" }.join(' OR ')
      result_default = permissions.map { |p| "false AS #{p}" }.join(', ')

      sql = <<~SQL
      SELECT namespace_ids.namespace_id, #{permission_select}
        FROM (#{value_list.to_sql}) AS namespace_ids (namespace_id, namespace_ids),
        LATERAL (
          (
           #{Member.select(permissions.join(', '))
              .left_outer_joins(:member_role)
              .where("members.source_type = 'Namespace' AND members.source_id = namespace_ids.namespace_id")
              .with_user(user)
              .where(permission_condition)
              .limit(1).to_sql}
          ) UNION ALL
          (
            #{Member.select(permissions.join(', '))
              .left_outer_joins(:member_role)
              .where("members.source_type = 'Namespace' AND members.source_id IN (SELECT UNNEST(namespace_ids) as ids)")
              .with_user(user)
              .where(permission_condition)
              .limit(1).to_sql}
          ) UNION ALL
          (
            SELECT #{result_default}
          )
          LIMIT 1
        ) AS custom_permissions
        GROUP BY namespace_ids.namespace_id;
      SQL

      grouped_by_group = ApplicationRecord.connection.execute(sql).to_a.group_by do |h|
        h['namespace_id']
      end

      grouped_by_group.transform_values do |value|
        permissions.filter_map do |permission|
          permission if value.find { |custom_role| custom_role[permission.to_s] == true }
        end
      end
    end

    private

    attr_reader :groups, :user
  end
end
