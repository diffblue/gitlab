# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class VulnerabilitiesCountService
      COUNT_BATCH_SIZE = 50

      def initialize(project:, uuids:, states:, allowed_count:, vulnerability_age: nil)
        @project = project
        @uuids = uuids
        @states = states
        @allowed_count = allowed_count
        @vulnerability_age = vulnerability_age
      end

      attr_reader :project, :uuids, :states, :allowed_count, :vulnerability_age

      def execute
        result_count = 0
        exceeded_allowed_count = false

        uuids.each_slice(COUNT_BATCH_SIZE) do |uuids_batch|
          result_count += count_vulnerabilities(uuids_batch)

          if result_count > allowed_count
            exceeded_allowed_count = true
            break
          end
        end

        { count: result_count, exceeded_allowed_count: exceeded_allowed_count }
      end

      private

      def count_vulnerabilities(uuids_batch)
        return count_vulnerabilities_by_uuid_state_and_age(uuids_batch) if vulnerability_age_valid?

        vulnerabilities_reads_by_uuid_and_state(uuids_batch).count
      end

      def vulnerability_age_valid?
        vulnerability_age.present? &&
          vulnerability_age[:operator].in?(%i[greater_than less_than]) &&
          vulnerability_age[:interval].in?(%i[day week month year]) &&
          vulnerability_age[:value].is_a?(::Integer)
      end

      def count_vulnerabilities_by_uuid_state_and_age(uuids_batch)
        Vulnerability
          .by_age(vulnerability_age[:operator], age_in_days(vulnerability_age))
          .by_ids(vulnerabilities_reads_by_uuid_and_state(uuids_batch).select(:vulnerability_id))
          .count
      end

      def age_in_days(vulnerability_age)
        interval_in_days = case vulnerability_age[:interval]
                           when :day then 1
                           when :week then 7
                           when :month then 30
                           when :year then 365
                           end

        vulnerability_age[:value] * interval_in_days
      end

      def vulnerabilities_reads_by_uuid_and_state(uuids_batch)
        project.vulnerability_reads.by_uuid(uuids_batch).with_states(states)
      end
    end
  end
end
