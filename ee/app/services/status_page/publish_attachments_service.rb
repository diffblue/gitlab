# frozen_string_literal: true

module StatusPage
  # Publishes Attachments from incident comments and descriptions to s3
  # Should only be called from publish details or a service that inherits from the publish_base_service
  class PublishAttachmentsService
    include ::Gitlab::Utils::StrongMemoize
    include ::StatusPage::PublicationServiceResponses

    def initialize(project:, issue:, user_notes:, storage_client:)
      @project = project
      @issue = issue
      @user_notes = user_notes
      @storage_client = storage_client
      @total_uploads = existing_keys.size
      @has_errors = false
    end

    def execute
      publish_description_attachments
      publish_user_note_attachments

      return file_upload_error if @has_errors

      success
    end

    private

    attr_reader :project, :issue, :user_notes, :storage_client

    def publish_description_attachments
      publish_markdown_uploads(
        markdown_field: issue.description
      )
    end

    def publish_user_note_attachments
      user_notes.each do |user_note|
        publish_markdown_uploads(
          markdown_field: user_note.note
        )
      end
    end

    def publish_markdown_uploads(markdown_field:)
      scanner = FileUploader::MARKDOWN_PATTERN.scan(markdown_field)
      scanner.each do |match|
        secret = match[0]
        file_name = match[1]

        break if @total_uploads >= Gitlab::StatusPage::Storage::MAX_UPLOADS

        key = upload_path(secret, file_name)
        next if existing_keys.include? key

        file = find_file(secret, file_name)
        next if file.nil?

        upload_file(key, file)
      end
    end

    def upload_file(key, file)
      file.open do |open_file|
        # Send files to s3 storage in parts (handles large files)
        storage_client.multipart_upload(key, open_file)
        @total_uploads += 1
      end
    rescue Gitlab::StatusPage::Storage::Error => e
      # In production continue uploading other files if one fails But report the failure to Sentry
      # raise errors in development and test
      @has_errors = true
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
    end

    def existing_keys
      strong_memoize(:existing_keys) do
        storage_client.list_object_keys(uploads_path)
      end
    end

    def upload_path(secret, file_name)
      Gitlab::StatusPage::Storage.upload_path(issue.iid, secret, file_name)
    end

    def uploads_path
      Gitlab::StatusPage::Storage.uploads_path(issue.iid)
    end

    def find_file(secret, file_name)
      # Uploader object behaves like a file with an 'open' method
      UploaderFinder.new(project, secret, file_name).execute
    end

    def file_upload_error
      error('One or more files did not upload properly')
    end
  end
end
