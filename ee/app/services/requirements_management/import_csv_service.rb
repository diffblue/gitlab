# frozen_string_literal: true

module RequirementsManagement
  class ImportCsvService < ::Issuable::ImportCsv::BaseService
    def execute
      raise Gitlab::Access::AccessDeniedError unless Ability.allowed?(user, :create_requirement, project)

      super
    end

    private

    def create_object(attributes)
      super[:issue]
    end

    def create_object_class
      ::Issues::CreateService
    end

    def email_results_to_user
      Notify.import_requirements_csv_email(user.id, project.id, results).deliver_later
    end

    def attributes_for(row)
      super.merge(issue_type: 'requirement')
    end
  end
end
