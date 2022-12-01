# frozen_string_literal: true

module Gitlab
  module Geo
    # Returns an ID range to allow iteration over a destination table and its
    # source replicable table. Repeats from the beginning after it reaches
    # the end.
    #
    # Used by Geo in particular to iterate over a replicable and its destination
    # table.
    #
    # Tracks a cursor for each table, by "key". If the table is smaller than
    # batch_size, then a range for the whole table is returned on every call.
    class BaseBatcher
      # @param [Class] destination_class the class of the table to iterate on
      # @param [String] key to identify the cursor. Note, cursor is already unique
      #   per table.
      # @param [Integer] batch_size to limit the number of records in a batch
      def initialize(source_class, destination_class, source_foreign_key, key:, batch_size: 1000)
        @source_class = source_class
        @source_foreign_key = source_foreign_key
        @destination_class = destination_class
        @key = key
        @batch_size = batch_size
      end

      # @return [Range] a range of IDs. `nil` if 0 records at or after the cursor.
      def next_range!
        batch_first_id = cursor_id
        batch_last_id  = get_batch_last_id(batch_first_id)
        return unless batch_last_id

        batch_first_id..batch_last_id
      end

      private

      attr_reader :source_class, :source_foreign_key, :destination_class, :key, :batch_size

      # @private
      #
      # Get the last ID of the batch. Increment the cursor or reset it if at end.
      #
      # @param [Integer] batch_first_id the first ID of the batch
      # @return [Integer] batch_last_id the last ID of the batch (not the table)
      def get_batch_last_id(batch_first_id)
        source_class_last_id, more_records = get_source_batch_last_id(batch_first_id)
        destination_class_last_id, more_destination_records = get_destination_batch_last_id(batch_first_id)

        batch_last_id = if source_class_last_id && destination_class_last_id
                          [source_class_last_id, destination_class_last_id].max
                        else
                          source_class_last_id || destination_class_last_id
                        end

        if more_records || more_destination_records
          increment_batch(batch_last_id)
        elsif batch_first_id > 1
          reset
        end

        batch_last_id
      end

      # @private
      #
      # Get the last ID of the of the batch (not the table) for the replicable
      # and check if there are more rows in the table.
      #
      # @param [Integer] batch_first_id the first ID of the batch
      # @return [Integer, Boolean] A tuple with the the last ID of the batch (not the table),
      #                            and whether or not have more rows to check in the table
      def get_source_batch_last_id(batch_first_id)
        sql = <<~SQL
          SELECT MAX(batch.#{source_class.primary_key}) AS batch_last_id,
          EXISTS (
            SELECT #{source_class.primary_key}
            FROM #{source_class.table_name}
            WHERE #{source_class.primary_key} > MAX(batch.#{source_class.primary_key})
          ) AS more_rows
          FROM (
            SELECT #{source_class.primary_key}
            FROM #{source_class.table_name}
            WHERE #{source_class.primary_key} >= #{batch_first_id}
            ORDER BY #{source_class.primary_key}
            LIMIT #{batch_size}) AS batch;
        SQL

        result = source_class.connection.exec_query(sql).first

        [result["batch_last_id"], result["more_rows"]]
      end

      # @private
      #
      # Get the last ID of the of the batch (not the table) for the destination
      # and check if there are more rows in the table.
      #
      # This query differs from the replicable query by:
      #
      # - We check against the foreign key IDs not the destination IDs;
      # - In the where clause of the more_rows part, we use greater
      #   than or equal. This allows the batcher to switch to the
      #   destination table while getting the last ID of the batch
      #   when the previous batch included the end of the replicable
      #   table but there are orphaned registries where the foreign key
      #   ids are higher than the last replicable id;
      #
      # @param [Integer] batch_first_id the first ID of the batch
      # @return [Integer, Boolean] A tuple with the the last ID of the batch (not the table),
      #                            and whether or not have more rows to check in the table
      def get_destination_batch_last_id(batch_first_id)
        sql = <<~SQL
          SELECT MAX(batch.#{source_foreign_key}) AS batch_last_id,
          EXISTS (
            SELECT #{source_foreign_key}
            FROM #{destination_class.table_name}
            WHERE #{source_foreign_key} > MAX(batch.#{source_foreign_key})
          ) AS more_rows
          FROM (
            SELECT #{source_foreign_key}
            FROM #{destination_class.table_name}
            WHERE #{source_foreign_key} >= #{batch_first_id}
            ORDER BY #{source_foreign_key}
            LIMIT #{batch_size}) AS batch;
        SQL

        result = destination_class.connection.exec_query(sql).first

        [result["batch_last_id"], result["more_rows"]]
      end

      def reset
        set_cursor_id(1)
      end

      def increment_batch(batch_last_id)
        set_cursor_id(batch_last_id + 1)
      end

      # @private
      #
      # @return [Integer] the cursor ID, or 1 if it is not set
      def cursor_id
        Rails.cache.fetch("#{cache_key}:cursor_id") || 1
      end

      def set_cursor_id(id)
        Rails.cache.write("#{cache_key}:cursor_id", id)
      end

      def cache_key
        @cache_key ||= "#{self.class.name.parameterize}:#{destination_class.name.parameterize}:#{key}:cursor_id"
      end
    end
  end
end
