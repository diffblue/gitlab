# frozen_string_literal: true

module EE
  module SystemNotes
    module MergeRequestsService
      def merge_when_checks_pass(sha)
        body = "enabled an automatic merge when all merge checks for #{sha} pass"

        create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
      end
    end
  end
end
