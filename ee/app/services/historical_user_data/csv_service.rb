# frozen_string_literal: true

module HistoricalUserData
  class CsvService
    FILESIZE_LIMIT = 15.megabytes

    def initialize(historical_data_relation)
      @historical_data_relation = historical_data_relation
    end

    def generate
      header_csv + csv_builder.render(FILESIZE_LIMIT)
    end

    private

    attr_reader :historical_data_relation

    def csv_builder
      @csv_builder ||= CsvBuilder.new(historical_data_relation, header_to_value_hash)
    end

    def header_to_value_hash
      {
        'Date' => -> (historical_datum) { historical_datum.recorded_at.utc.to_s(:csv) },
        'Billable User Count' => 'active_user_count'
      }
    end

    def license
      @license ||= License.current
    end

    def header_csv
      CSV.generate do |csv|
        csv << ['License Key', license.normalized_data]
        csv << ['Email', license.licensee_email]
        csv << ['License Start Date', license.starts_at&.to_s(:csv)]
        csv << ['License End Date', license.expires_at&.to_s(:csv)]
        csv << ['Company', license.licensee_company]
        csv << ['Generated At', Time.current.utc.to_s(:csv)]
        csv << ['', '']
      end
    end
  end
end
