# frozen_string_literal: true

module Types
  class TimeboxErrorReasonEnum < IssuableSortEnum
    graphql_name 'TimeboxReportErrorReason'
    description 'Category of error.'

    value 'UNSUPPORTED', 'This type does not support timebox reports.', value: :unsupported_type
    value 'MISSING_DATES', 'One or both of start_date and due_date is missing.', value: :missing_dates
    value 'TOO_MANY_EVENTS', 'There are too many events.', value: :too_many_events
  end
end
