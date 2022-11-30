# frozen_string_literal: true

class UserPermissionExportUpload < ApplicationRecord
  include WithUploads

  belongs_to :user, -> { where(admin: true) }

  mount_uploader :file, AttachmentUploader

  validates :status, presence: true
  validates :file, length: { maximum: 255 }
  validate :file_presence, if: :finished?

  state_machine :status, initial: :created do
    event :start do
      transition created: :running
    end

    event :finish do
      transition running: :finished
    end

    event :failed do
      transition [:created, :running] => :failed
    end

    state :created, value: 0
    state :running, value: 1
    state :finished, value: 2
    state :failed, value: 3
  end

  private

  def file_presence
    errors.add(:file, "can't be blank") unless file.present?
  end
end
