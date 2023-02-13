# frozen_string_literal: true

module RequirementsManagement
  class ExportCsvService < ExportCsv::BaseService
    def email(user)
      Notify.requirements_csv_email(user, resource_parent, csv_data, csv_builder.status).deliver_now
    end

    private

    def associations_to_preload
      [{ requirement: :recent_test_reports }, :author]
    end

    def header_to_value_hash
      {
        'Requirement ID' => ->(work_item) { work_item.requirement.iid },
        'Title' => 'title',
        'Description' => 'description',
        'Author' => ->(work_item) { work_item.author&.name },
        'Author Username' => ->(work_item) { work_item.author&.username },
        'Created At (UTC)' => ->(work_item) { work_item.created_at.utc },
        'State' => ->(work_item) { work_item.requirement.last_test_report_state == 'passed' ? 'Satisfied' : '' },
        'State Updated At (UTC)' => ->(work_item) { work_item.requirement.latest_report&.created_at&.utc }
      }
    end
  end
end
