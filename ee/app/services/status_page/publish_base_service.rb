# frozen_string_literal: true

module StatusPage
  class PublishBaseService
    include Gitlab::Utils::StrongMemoize
    include StatusPage::PublicationServiceResponses

    def initialize(project:)
      @project = project
    end

    def execute(...)
      return error_feature_not_available unless feature_available?
      return error_no_storage_client unless storage_client

      process(...)
    end

    private

    attr_reader :project

    def process(*args)
      raise NotImplementedError
    end

    def storage_client
      strong_memoize(:strong_memoize) do
        project.status_page_setting&.storage_client
      end
    end

    def serializer
      strong_memoize(:serializer) do
        # According to development/reusing_abstractions.html#abstractions
        # serializers can only be used from controllers.
        # For the Status Page however, we generate JSON in background jobs.
        # rubocop: disable CodeReuse/Serializer
        StatusPage::IncidentSerializer.new
        # rubocop: enable CodeReuse/Serializer
      end
    end

    def feature_available?
      project.status_page_setting&.enabled?
    end

    def upload_json(key, json)
      return error_limit_exceeded(key) if limit_exceeded?(json)

      content = json.to_json
      storage_client.upload_object(key, content)

      success(object_key: key)
    end

    def multipart_upload(key, uploader)
      storage_client.multipart_upload(key, uploader)
    end

    def delete_object(key)
      storage_client.delete_object(key)
    end

    def recursive_delete(prefix)
      storage_client.recursive_delete(prefix)
    end

    def limit_exceeded?(json)
      !Gitlab::Utils::DeepSize
        .new(json, max_size: ::Gitlab::StatusPage::Storage::JSON_MAX_SIZE)
        .valid?
    end

    def error_limit_exceeded(key)
      error("Failed to upload #{key}: Limit exceeded")
    end

    def error_feature_not_available
      error('Feature not available')
    end

    def error_no_storage_client
      error('No storage client available. Is the status page setting activated?')
    end
  end
end
