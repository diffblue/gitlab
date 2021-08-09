# frozen_string_literal: true

module EE
  module ServiceDeskSetting
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      belongs_to :file_template_project, class_name: "Project", foreign_key: 'file_template_project_id'
    end

    override :source_template_project
    def source_template_project
      file_template_project
    end
  end
end
