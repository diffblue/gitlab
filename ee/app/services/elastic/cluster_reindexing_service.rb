# frozen_string_literal: true

module Elastic
  class ClusterReindexingService
    include Gitlab::Utils::StrongMemoize

    INITIAL_INDEX_OPTIONS = { # Optimized for writes
        refresh_interval: '10s',
        number_of_replicas: 0,
        translog: { durability: 'async' }
    }.freeze

    DELETE_ORIGINAL_INDEX_AFTER = 14.days

    REINDEX_MAX_RETRY_LIMIT = 10

    def execute
      case current_task.state.to_sym
      when :initial
        initial!
      when :indexing_paused
        indexing_paused!
      when :reindexing
        reindexing!
      end
    end

    def current_task
      strong_memoize(:elastic_current_task) do
        Elastic::ReindexingTask.current
      end
    end

    private

    def alias_names
      [elastic_helper.target_name] + elastic_helper.standalone_indices_proxies.map(&:index_name)
    end

    def default_index_options(alias_name:, index_name:)
      {
        refresh_interval: elastic_helper.get_settings(index_name: index_name).dig('refresh_interval'), # Use existing setting or nil for default
        number_of_replicas: Elastic::IndexSetting[alias_name].number_of_replicas,
        translog: { durability: 'request' }
      }
    end

    def initial!
      if Elastic::DataMigrationService.pending_migrations?
        # migrations may have paused indexing so we do not want to unpause when aborting the reindexing process
        abort_reindexing!('You have unapplied advanced search migrations. Please wait until it is finished', unpause_indexing: false)
        return false
      end

      # Pause indexing
      Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: true)

      unless elastic_helper.alias_exists?
        abort_reindexing!('Your Elasticsearch index must first use aliases before you can use this feature. Please recreate your index from scratch before reindexing.')
        return false
      end

      expected_free_size = alias_names.sum { |name| elastic_helper.index_size_bytes(index_name: name) } * 2
      if elastic_helper.cluster_free_size_bytes < expected_free_size
        abort_reindexing!("You should have at least #{expected_free_size} bytes of storage available to perform reindexing. Please increase the storage in your Elasticsearch cluster before reindexing.")
        return false
      end

      current_task.update!(state: :indexing_paused)

      true
    end

    def indexing_paused!
      target_classes = current_task.target_classes

      items_to_reindex = []

      target_classes.each do |klass|
        alias_name = elastic_helper.klass_to_alias_name(klass: klass)
        index_names = elastic_helper.target_index_names(target: alias_name).keys

        index_names.each_with_index do |index_name, index|
          name_suffix = "-reindex-#{current_task.id}-#{index}"

          alias_info = load_alias_info(klass: klass, name_suffix: name_suffix)

          items_to_reindex << {
            alias_name: alias_info.each_value.first,
            index_name_from: index_name,
            index_name_to: alias_info.each_key.first
          }
        end
      end

      launch_subtasks(items_to_reindex)

      current_task.update!(state: :reindexing)

      true
    end

    def load_alias_info(klass:, name_suffix:)
      if klass == Repository # Repository is a marker class for the main index
        elastic_helper.create_empty_index(
          with_alias: false,
          options: { settings: INITIAL_INDEX_OPTIONS, name_suffix: name_suffix }
        )
      else
        elastic_helper.create_standalone_indices(
          with_alias: false,
          options: { settings: INITIAL_INDEX_OPTIONS, name_suffix: name_suffix },
          target_classes: [klass]
        )
      end
    end

    def launch_subtasks(items_to_reindex)
      items_to_reindex.each do |item|
        # Record documents count
        documents_count = elastic_helper.documents_count(index_name: item[:index_name_from])
        # Create all subtasks
        subtask = current_task.subtasks.create!(item.merge(documents_count: documents_count))

        max_slice = elastic_helper.get_settings(index_name: item[:index_name_from]).dig('number_of_shards').to_i * current_task.slice_multiplier
        0.upto(max_slice - 1).to_a.each do |slice|
          subtask.slices.create!(
            elastic_max_slice: max_slice,
            elastic_slice: slice
          )
        end
      end

      trigger_reindexing_slices
    end

    def save_documents_count!(refresh:)
      current_task.subtasks.each do |subtask|
        elastic_helper.refresh_index(index_name: subtask.index_name_to) if refresh

        new_documents_count = elastic_helper.documents_count(index_name: subtask.index_name_to)
        subtask.update!(documents_count_target: new_documents_count)
      end
    end

    def check_subtasks_and_reindex_slices
      save_documents_count!(refresh: false)

      slices_failed = 0
      slices_in_progress = 0
      totals_do_not_match = 0

      current_task.subtasks.each do |subtask|
        subtask.slices.started.each do |slice|
          # Get task status
          task_status = elastic_helper.task_status(task_id: slice.elastic_task)

          # Check if task is complete
          slices_in_progress += 1 unless task_status['completed']

          # Check for reindexing error
          reindexing_error = task_status.dig('error', 'type')
          if reindexing_error
            slices_failed += 1

            message = "Task #{slice.elastic_task} has failed with an Elasticsearch error: #{reindexing_error}."
            retry_or_abort_after_limit(subtask, slice, message, { elasticsearch_error_type: reindexing_error, elastic_slice: slice.elastic_slice })
            slices_in_progress += 1

            next
          end

          # Check totals match if task complete
          response = task_status['response']
          next unless task_status['completed'] && response['total'] != (response['created'] + response['updated'] + response['deleted'])

          message = "Task #{slice.elastic_task} total: #{response['total']} is not equal to updated: #{response['updated']} + created: #{response['created']} + deleted: #{response['deleted']}."
          retry_or_abort_after_limit(subtask, slice, message, { elastic_slice: slice.elastic_slice })
          slices_in_progress += 1
          totals_do_not_match += 1
        end
      end

      # Kick off more reindexing slices
      slices_in_progress = trigger_reindexing_slices(slices_in_progress)

      # Schedule another check in 1 minute
      ::ElasticClusterReindexingCronWorker.perform_in(1.minute)

      slices_in_progress == 0 && slices_failed == 0 && totals_do_not_match == 0
    rescue Elasticsearch::Transport::Transport::Error
      abort_reindexing!("Couldn't load task status")

      false
    end

    def retry_or_abort_after_limit(subtask, slice, message, additional_logs)
      if slice.retry_attempt < REINDEX_MAX_RETRY_LIMIT
        retry_slice(subtask, slice, "#{message} Retrying.")
      else
        abort_reindexing!("#{message}. Retry limit reached. Aborting reindexing.", additional_logs: additional_logs)
      end
    end

    def retry_slice(subtask, slice, message, additional_options = {})
      warn = {
        message: message,
        gitlab_task_id: current_task.id,
        gitlab_task_state: current_task.state,
        gitlab_subtask_id: subtask.id,
        gitlab_subtask_elastic_slice: slice.elastic_slice,
        gitlab_subtask_elastic_task: slice.elastic_task
      }.merge(additional_options)
      logger.warn(warn)

      task_id = elastic_helper.reindex(from: subtask.index_name_from, to: subtask.index_name_to, max_slice: slice.elastic_max_slice, slice: slice.elastic_slice)
      retry_attempt = slice.retry_attempt + 1
      logger.info(message: "Retrying (attempt #{retry_attempt}) reindex task #{task_id} from #{subtask.index_name_from} to #{subtask.index_name_to} started for slice #{slice.elastic_slice}.")
      slice.update!(elastic_task: task_id, retry_attempt: retry_attempt)
    end

    def compare_documents_count
      save_documents_count!(refresh: true)

      current_task.subtasks.each do |subtask|
        old_documents_count = subtask.documents_count
        new_documents_count = subtask.documents_count_target
        next if old_documents_count == new_documents_count

        abort_reindexing!("Documents count is different, Count from new index: #{new_documents_count} Count from original index: #{old_documents_count}. This likely means something went wrong during reindexing.")

        return false
      end

      true
    end

    def trigger_reindexing_slices(slices_in_progress = 0)
      current_task.subtasks.each do |subtask|
        slices_to_start = current_task.max_slices_running - slices_in_progress
        break if slices_to_start == 0

        subtask.slices.not_started.limit(slices_to_start).each do |slice|
          task_id = elastic_helper.reindex(from: subtask.index_name_from, to: subtask.index_name_to, max_slice: slice.elastic_max_slice, slice: slice.elastic_slice)
          logger.info(message: "Reindex task #{task_id} from #{subtask.index_name_from} to #{subtask.index_name_to} started for slice #{slice.elastic_slice}.")

          slice.update!(elastic_task: task_id)
          slices_in_progress += 1
        end
      end

      slices_in_progress
    end

    def apply_default_index_options
      current_task.subtasks.each do |subtask|
        elastic_helper.update_settings(
          index_name: subtask.index_name_to,
          settings: default_index_options(alias_name: subtask.alias_name, index_name: subtask.index_name_from)
        )
      end
    end

    def switch_alias_to_new_index
      actions = []

      current_task.subtasks.group_by(&:alias_name).each do |alias_name, subtasks|
        subtasks.each_with_index do |subtask, index|
          # Pick the last index as the write one
          is_write_index = index == subtasks.length - 1
          actions += [
            {
              remove: { index: subtask.index_name_from, alias: subtask.alias_name }
            },
            {
              add: { index: subtask.index_name_to, alias: subtask.alias_name, is_write_index: is_write_index }
            }
          ]
        end
      end

      elastic_helper.multi_switch_alias(actions: actions)
    end

    def finalize_reindexing
      Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: false)

      current_task.update!(state: :success, delete_original_index_at: DELETE_ORIGINAL_INDEX_AFTER.from_now)
    end

    def reindexing!
      return false unless check_subtasks_and_reindex_slices
      return false unless compare_documents_count

      apply_default_index_options
      switch_alias_to_new_index
      finalize_reindexing

      true
    end

    def abort_reindexing!(reason, additional_logs: {}, unpause_indexing: true)
      error = { message: 'elasticsearch_reindex_error', error: reason, gitlab_task_id: current_task.id, gitlab_task_state: current_task.state }
      logger.error(error.merge(additional_logs))

      current_task.update!(
        state: :failure,
        error_message: reason
      )

      # Unpause indexing
      Gitlab::CurrentSettings.update!(elasticsearch_pause_indexing: false) if unpause_indexing
    end

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end

    def elastic_helper
      Gitlab::Elastic::Helper.default
    end
  end
end
