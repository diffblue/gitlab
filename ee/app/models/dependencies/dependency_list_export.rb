# frozen_string_literal: true
module Dependencies
  class DependencyListExport < ApplicationRecord
    include FileStoreMounter

    mount_file_store_uploader AttachmentUploader

    belongs_to :project
    belongs_to :group
    belongs_to :author, class_name: 'User', foreign_key: :user_id, inverse_of: :dependency_list_exports

    validates :project, presence: true, unless: :group
    validates :group, presence: true, unless: :project
    validates :status, presence: true
    validates :file, presence: true, if: :finished?
    validate :only_one_exportable

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

    def exportable
      project || group
    end

    def exportable=(value)
      case value
      when Project
        make_project_level_export(value)
      when Group
        make_group_level_export(value)
      else
        raise "Can not assign #{value.class} as exportable"
      end
    end

    private

    def make_project_level_export(project)
      self.project = project
      self.group = nil
    end

    def make_group_level_export(group)
      self.project = nil
      self.group = group
    end

    def only_one_exportable
      errors.add(:base, _('Project & Group can not be assigned at the same time')) if project && group
    end
  end
end
