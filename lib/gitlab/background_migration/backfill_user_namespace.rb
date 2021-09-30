# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the `namespaces.type` column, replacing any
    # instances of `NULL` with `User`
    class BackfillUserNamespace
      def perform(start_id, stop_id, *args)
        ActiveRecord::Base.connection.execute(<<~SQL)
          UPDATE namespaces SET type = 'User'
          WHERE id BETWEEN #{start_id} AND #{stop_id}
            AND type IS NULL
        SQL
      end
    end
  end
end
