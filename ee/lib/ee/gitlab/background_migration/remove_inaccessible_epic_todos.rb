# frozen_string_literal: true
# rubocop:disable Style/Documentation

module EE
  module Gitlab
    module BackgroundMigration
      module RemoveInaccessibleEpicTodos
        extend ::Gitlab::Utils::Override

        class User < ActiveRecord::Base
        end

        class Todo < ActiveRecord::Base
          belongs_to :epic, foreign_key: :target_id
          belongs_to :user
        end

        class Member < ActiveRecord::Base
          include FromUnion

          self.inheritance_column = :_type_disabled
          self.enumerate_columns_in_select_statements = true
        end

        class GroupGroupLink < ActiveRecord::Base
        end

        class Epic < ActiveRecord::Base
          belongs_to :group

          def can_read_confidential?(user)
            group.max_member_access_for_user(user) >= ::Gitlab::Access::REPORTER
          end
        end

        class Group < ActiveRecord::Base
          self.table_name = 'namespaces'
          self.inheritance_column = :_type_disabled

          def max_member_access_for_user(user)
            max_member_access = members_with_parents.where(user_id: user)
                                  .reorder(access_level: :desc)
                                  .first
                                  &.access_level

            max_member_access || ::Gitlab::Access::NO_ACCESS
          end

          def members_with_parents
            group_hierarchy_members = Member.where(source_type: 'Namespace', source_id: source_ids)

            Member.from_union([group_hierarchy_members,
                               members_from_self_and_ancestor_group_shares])
          end

          # rubocop:disable Metrics/AbcSize
          # this is taken from Group model, so instead of doing additional
          # refactoring let's keep it close to the original
          def members_from_self_and_ancestor_group_shares
            group_group_link_table = GroupGroupLink.arel_table
            group_member_table = Member.arel_table

            group_group_links_query = GroupGroupLink.where(shared_group_id: source_ids)
            cte = ::Gitlab::SQL::CTE.new(:group_group_links_cte, group_group_links_query)
            cte_alias = cte.table.alias(GroupGroupLink.table_name)

            # Instead of members.access_level, we need to maximize that access_level at
            # the respective group_group_links.group_access.
            member_columns = Member.attribute_names.map do |column_name|
              if column_name == 'access_level'
                smallest_value_arel([cte_alias[:group_access], group_member_table[:access_level]],
                                    'access_level')
              else
                group_member_table[column_name]
              end
            end

            Member
              .with(cte.to_arel)
              .select(*member_columns)
              .from([group_member_table, cte.alias_to(group_group_link_table)])
              .where(group_member_table[:requested_at].eq(nil))
              .where(group_member_table[:source_id].eq(group_group_link_table[:shared_with_group_id]))
              .where(group_member_table[:source_type].eq('Namespace'))
          end
          # rubocop:enable Metrics/AbcSize

          def source_ids
            return id unless parent_id

            ::Gitlab::ObjectHierarchy
              .new(self.class.where(id: id))
              .base_and_ancestors
              .reorder(nil).select(:id)
          end

          def smallest_value_arel(args, column_alias)
            Arel::Nodes::As.new(
              Arel::Nodes::NamedFunction.new('LEAST', args),
              Arel::Nodes::SqlLiteral.new(column_alias))
          end
        end

        override :perform
        def perform(start_id, stop_id)
          confidential_epic_ids = Epic.where(confidential: true).where(id: start_id..stop_id).ids
          epic_todos = Todo
            .where(target_type: 'Epic', target_id: confidential_epic_ids)
            .includes(:epic, :user)
          ids_to_delete = not_readable_epic_todo_ids(epic_todos)

          logger.info(message: 'Deleting confidential epic todos', todo_ids: ids_to_delete)
          Todo.where(id: ids_to_delete).delete_all
        end

        private

        def not_readable_epic_todo_ids(todos)
          todos.map do |todo|
            next todo.id unless todo.epic
            next if todo.epic.can_read_confidential?(todo.user)

            todo.id
          end.compact
        end

        def logger
          @logger ||= ::Gitlab::BackgroundMigration::Logger.build
        end
      end
    end
  end
end
