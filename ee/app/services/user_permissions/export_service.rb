# frozen_string_literal: true

module UserPermissions
  class ExportService
    def execute
      ServiceResponse.success(payload: { csv_data: csv_builder.render })
    end

    private

    def csv_builder
      @csv_builder ||= CsvBuilder.new(data, header_to_value_hash)
    end

    def data
      Member
        .active_without_invites_and_requests
        .with_csv_entity_associations
    end

    def header_to_value_hash
      {
        'Username' => 'user_username',
        'Email' => 'user_email',
        'Type' => 'source_kind',
        'Path' => -> (member) { member.source&.full_path },
        'Access Level' => 'human_access',
        'Last Activity' => 'user_last_activity_on'
      }
    end
  end
end
