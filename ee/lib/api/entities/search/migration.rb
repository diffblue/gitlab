# frozen_string_literal: true

module API
  module Entities
    module Search
      class Migration < Grape::Entity # rubocop:disable Search/NamespacedClass
        expose :version, documentation: { type: 'int', example: 20230427555555 }
        expose :name, documentation: { type: 'string', example: 'BackfillHiddenOnMergeRequests' }

        # rubocop:disable Style/SymbolProc
        expose :started_at, documentation: { type: 'dateTime', example: '2023-05-14T12:30:50.355Z' } do |migration|
          migration.started_at
        end

        expose :completed_at, documentation: { type: 'dateTime', example: '2023-05-16T12:30:50.355Z' } do |migration|
          migration.completed_at
        end

        expose :completed, documentation: { type: 'boolean', example: true } do |migration|
          migration.load_completed_from_index
        end

        expose :obsolete, documentation: { type: 'boolean', example: false } do |migration|
          migration.obsolete?
        end

        expose :migration_state, documentation: { type: 'hash', example: { "task_id" => "task_id" } } do |migration|
          migration.migration_state
        end
        # rubocop:enable Style/SymbolProc
      end
    end
  end
end
