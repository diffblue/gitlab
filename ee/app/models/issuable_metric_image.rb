# frozen_string_literal: true

class IssuableMetricImage < ApplicationRecord
  include Gitlab::FileTypeDetection
  include FileStoreMounter
  include WithUploads

  belongs_to :issue, class_name: 'Issue', foreign_key: 'issue_id', inverse_of: :metric_images

  attribute :file_store, :integer, default: -> { IssuableMetricImageUploader.default_store }

  mount_file_store_uploader IssuableMetricImageUploader

  validates :issue, presence: true
  validates :file, presence: true
  validate :validate_file_is_image
  validates :url, length: { maximum: 255 }, public_url: { allow_blank: true }
  validates :url_text, length: { maximum: 128 }

  scope :order_created_at_asc, -> { order(created_at: :asc) }

  MAX_FILE_SIZE = 1.megabyte.freeze

  def self.available_for?(project)
    project&.feature_available?(:incident_metric_upload)
  end

  def filename
    @filename ||= file&.filename
  end

  def file_path
    @file_path ||= begin
      return file&.url unless file&.upload

      # If we're using a CDN, we need to use the full URL
      asset_host = ActionController::Base.asset_host || Gitlab.config.gitlab.base_url
      local_path = Gitlab::Routing.url_helpers.issuable_metric_image_upload_path(
        filename: file.filename,
        id: file.upload.model_id,
        model: self.class.name.underscore,
        mounted_as: 'file'
      )

      Gitlab::Utils.append_path(asset_host, local_path)
    end
  end

  private

  def valid_file_extensions
    SAFE_IMAGE_EXT
  end

  def validate_file_is_image
    unless image?
      message = _('does not have a supported extension. Only %{extension_list} are supported') % {
        extension_list: valid_file_extensions.to_sentence
      }
      errors.add(:file, message)
    end
  end
end
