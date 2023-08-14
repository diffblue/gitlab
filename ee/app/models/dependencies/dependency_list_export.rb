# frozen_string_literal: true
module Dependencies
  class DependencyListExport < ApplicationRecord
    include FileStoreMounter

    mount_file_store_uploader AttachmentUploader

    belongs_to :project
    belongs_to :group
    belongs_to :pipeline, class_name: 'Ci::Pipeline'
    belongs_to :author, class_name: 'User', foreign_key: :user_id, inverse_of: :dependency_list_exports

    validates :status, presence: true
    validates :file, presence: true, if: :finished?
    validates :export_type, presence: true

    validate :only_one_exportable

    enum export_type: {
      json: 0,
      sbom: 1
    }

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

      event :reset_state do
        transition running: :created
      end

      event :failed do
        transition [:created, :running] => :failed
      end
    end

    def retrieve_upload(_identifier, paths)
      Upload.find_by(model: self, path: paths)
    end

    def exportable
      pipeline || project || group
    end

    def exportable=(value)
      case value
      when Project
        make_project_level_export(value)
      when Group
        make_group_level_export(value)
      when Ci::Pipeline
        make_pipeline_level_export(value)
      else
        raise "Can not assign #{value.class} as exportable"
      end
    end

    private

    def make_project_level_export(project)
      self.project = project
      self.group = nil
      self.pipeline = nil
    end

    def make_group_level_export(group)
      self.project = nil
      self.group = group
      self.pipeline = nil
    end

    def make_pipeline_level_export(pipeline)
      self.project = nil
      self.group = nil
      self.pipeline = pipeline
    end

    def only_one_exportable
      errors.add(:base, 'Only one exportable is required') unless [project, group, pipeline].one?
    end
  end
end
