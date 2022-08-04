# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # class that will populate issue boards with iteration cadence id for boards scopped to current iteration
      module BackfillIterationCadenceIdForBoards
        BATCH_SIZE = 100

        class MigrationBoard < ApplicationRecord
          include EachBatch

          self.table_name = 'boards'
        end

        class MigrationGroup < ActiveRecord::Base
          self.inheritance_column = :_type_disabled

          self.table_name = 'namespaces'
        end

        class MigrationProject < ActiveRecord::Base
          self.table_name = 'projects'
        end

        class MigrationCadence < ApplicationRecord
          self.table_name = 'iterations_cadences'
        end

        def perform(board_type, method, start_id, end_id)
          if method == "up"
            back_fill_group_boards(start_id, end_id) if board_type == 'group'
            back_fill_project_boards(start_id, end_id) if board_type == 'project'
          else
            MigrationBoard.where.not(iteration_cadence_id: nil).where(id: start_id..end_id).each_batch(of: BATCH_SIZE) do |batch|
              batch.update_all(iteration_cadence_id: nil)
            end
          end
        end

        private

        def bulk_update(cadences_sql)
          MigrationBoard.connection.exec_query(<<~SQL)
            UPDATE boards SET
              iteration_id = CASE
                             WHEN boards_cadences.first_cadence_id IS NULL THEN NULL
                             ELSE boards.iteration_id
                             END,
              iteration_cadence_id = boards_cadences.first_cadence_id
            FROM #{cadences_sql}
            WHERE boards.id = boards_cadences.board_id
          SQL
        end

        def back_fill_group_boards(start_id, end_id)
          boards_relation(start_id, end_id).where.not(group_id: nil).each_batch(of: BATCH_SIZE) do |batch|
            range = batch.pick(Arel.sql('MIN(id)'), Arel.sql('MAX(id)'))

            sql = <<~SQL
              (
                SELECT
                  boards.id AS board_id,
                  (SELECT id FROM iterations_cadences WHERE group_id = ANY(traversal_ids) ORDER BY iterations_cadences.id LIMIT 1) AS first_cadence_id
                FROM boards
                INNER JOIN namespaces ON boards.group_id = namespaces.id
                WHERE boards.id BETWEEN #{range.first} AND #{range.last} AND boards.group_id IS NOT NULL AND iteration_id = -4
                ORDER BY first_cadence_id NULLS FIRST
              ) AS boards_cadences
            SQL

            bulk_update(sql)
          end
        end

        def back_fill_project_boards(start_id, end_id)
          boards_relation(start_id, end_id).where.not(project_id: nil).each_batch(of: BATCH_SIZE) do |batch|
            range = batch.pick(Arel.sql('MIN(id)'), Arel.sql('MAX(id)'))

            sql = <<~SQL
              (
                SELECT
                  boards.id AS board_id,
                  (SELECT id FROM iterations_cadences WHERE group_id = ANY(traversal_ids) ORDER BY iterations_cadences.id LIMIT 1) AS first_cadence_id
                FROM boards
                INNER JOIN projects ON boards.project_id = projects.id
                INNER JOIN namespaces ON projects.namespace_id = namespaces.id
                WHERE boards.id BETWEEN #{range.first} AND #{range.last} AND boards.project_id IS NOT NULL AND iteration_id = -4
                ORDER BY first_cadence_id NULLS FIRST
              ) AS boards_cadences
            SQL

            bulk_update(sql)
          end
        end

        def build_board_cadence_data(group_board_pairs)
          board_cadence_data = []

          group_board_pairs.each do |pair|
            cadence = MigrationCadence.where(group_id: MigrationGroup.where(id: pair.last).select('unnest(namespaces.traversal_ids) AS ids')).first

            board_cadence_data << if cadence.present?
                                    [pair.first, cadence.id, -4]
                                  else
                                    [pair.first, Arel::Nodes::SqlLiteral.new("NULL"), Arel::Nodes::SqlLiteral.new("NULL")]
                                  end
          end

          board_cadence_data
        end

        def boards_relation(start_id, end_id)
          MigrationBoard.where(iteration_id: -4).where(iteration_cadence_id: nil).where(id: start_id..end_id)
        end
      end
    end
  end
end
