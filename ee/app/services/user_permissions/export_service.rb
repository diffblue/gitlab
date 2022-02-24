# frozen_string_literal: true

module UserPermissions
  class ExportService
    def initialize(current_user)
      @current_user = current_user
    end

    def csv_data
      return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

      ServiceResponse.success(payload: csv_builder.render)
    end

    private

    attr_reader :current_user

    def allowed?
      current_user.can?(:export_user_permissions)
    end

    def csv_builder
      @csv_builder ||= CsvBuilders::Stream.new(data, header_to_value_hash)
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
