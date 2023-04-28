# frozen_string_literal: true

# Security::PureFindingsFinder
#
# This finder returns Active Record relation of `Security::Finding` model
# which is different than the other finders maintained by threat insights.
# It's called pure because it does not depend on report artifacts(mostly)
# and uses the data stored in the `Security::Finding` model.
#
# Arguments:
#   pipeline - object to filter findings
#   params:
#     severity:    Array<String>
#     confidence:  Array<String>
#     report_type: Array<String>
#     scope:       String
#     page:        Int
#     per_page:    Int

module Security
  class PureFindingsFinder < FindingsFinder
    def execute
      security_findings
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def available?
      pipeline.security_findings.exists?(["finding_data <> ?", "{}"])
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def security_findings
      super.with_feedbacks
           .with_vulnerability
    end
  end
end
