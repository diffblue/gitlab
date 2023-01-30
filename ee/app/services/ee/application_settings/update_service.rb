# frozen_string_literal: true

module EE
  module ApplicationSettings
    module UpdateService
      extend ::Gitlab::Utils::Override
      extend ActiveSupport::Concern

      override :execute
      def execute
        # Repository size limit comes as MB from the view
        limit = params.delete(:repository_size_limit)
        application_setting.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

        if params[:maintenance_mode] == false || params[:maintenance_mode_message] == ''
          params[:maintenance_mode_message] = nil
        end

        elasticsearch_shards = params.delete(:elasticsearch_shards)
        elasticsearch_replicas = params.delete(:elasticsearch_replicas)

        elasticsearch_namespace_ids = params.delete(:elasticsearch_namespace_ids)
        elasticsearch_project_ids = params.delete(:elasticsearch_project_ids)

        if result = super
          find_or_create_elasticsearch_index if params.keys.any? { |key| key.to_s.start_with?('elasticsearch') }
          update_elasticsearch_containers(ElasticsearchIndexedNamespace, elasticsearch_namespace_ids)
          update_elasticsearch_containers(ElasticsearchIndexedProject, elasticsearch_project_ids)
          update_elasticsearch_index_settings(number_of_replicas: elasticsearch_replicas, number_of_shards: elasticsearch_shards)
        end

        result
      end

      def update_elasticsearch_containers(klass, new_container_ids)
        return unless application_setting.elasticsearch_limit_indexing?
        return if new_container_ids.nil?

        new_container_ids = new_container_ids.split(',').map(&:to_i) unless new_container_ids.is_a?(Array)

        # Destroy any containers that have been removed. This runs callbacks, etc
        klass.remove_all(except: new_container_ids)

        # Disregard any duplicates that are already present
        new_container_ids -= klass.target_ids

        # Add new containers
        new_container_ids.each { |id| klass.create!(klass.target_attr_name => id) }
      end

      def update_elasticsearch_index_settings(number_of_replicas:, number_of_shards:)
        return if number_of_replicas.nil? && number_of_shards.nil?

        if number_of_shards&.respond_to?(:to_h)
          number_of_shards.to_h.each do |index_name, shards|
            replicas = number_of_replicas[index_name]

            next if shards.blank? || replicas.blank?

            Elastic::IndexSetting[index_name].update!(
              number_of_replicas: replicas.to_i,
              number_of_shards: shards.to_i
            )
          end
        else
          # This method still receives non-hash values from API
          Elastic::IndexSetting.every_alias do |setting|
            setting.update!(
              number_of_replicas: number_of_replicas || setting.number_of_replicas,
              number_of_shards: number_of_shards || setting.number_of_shards
            )
          end
        end
      end

      private

      def should_auto_approve_blocked_users?
        super || user_cap_increased?
      end

      def user_cap_increased?
        return false unless application_setting.previous_changes.key?(:new_user_signups_cap)

        previous_user_cap, current_user_cap = application_setting.previous_changes[:new_user_signups_cap]

        return false if previous_user_cap.nil?

        current_user_cap.nil? || current_user_cap > previous_user_cap
      end

      def find_or_create_elasticsearch_index
        # The order of checks is important. We should not attempt to create a new index
        # unless elasticsearch_indexing is enabled
        return unless application_setting.elasticsearch_indexing

        elasticsearch_helper.create_empty_index(options: { skip_if_exists: true })
        elasticsearch_helper.create_standalone_indices(options: { skip_if_exists: true })

        unless elasticsearch_helper.migrations_index_exists?
          elasticsearch_helper.create_migrations_index
          ::Elastic::DataMigrationService.mark_all_as_completed!
        end
      rescue Faraday::Error => e
        log_error(e)
      end

      def elasticsearch_helper
        @elasticsearch_helper ||= ::Gitlab::Elastic::Helper.new(client: elasticsearch_client)
      end

      def elasticsearch_client
        ::Gitlab::Elastic::Client.build(application_setting.elasticsearch_config)
      end
    end
  end
end
