# frozen_string_literal: true
module Dependencies
  class DependencyListExport < ApplicationRecord
    include FileStoreMounter

    mount_file_store_uploader AttachmentUploader

    belongs_to :project, inverse_of: :dependency_list_exports, optional: false
    belongs_to :author, class_name: 'User', foreign_key: :user_id, inverse_of: :dependency_list_exports

    validates :project, presence: true
    validates :status, presence: true
    validates :file, presence: true, if: :finished?

    state_machine :status, initial: :created do
      state :created, value: 0
      state :running, value: 1
      state :finished, value: 2
      state :failed, value: -1

      event :start do
        transition created: :running
      end

      event :finish do
        transition running: :finished
      end

      event :failed do
        transition [:created, :running] => :failed
      end
    end

    def retrieve_upload(_identifier, paths)
      Upload.find_by(model: self, path: paths)
    end
  end
end
