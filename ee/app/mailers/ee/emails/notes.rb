# frozen_string_literal: true

module EE
  module Emails
    module Notes
      def note_epic_email(recipient_id, note_id, reason = nil)
        setup_note_mail(note_id, recipient_id)
        add_group_headers

        @epic = @note.noteable
        @target_url = group_epic_url(*note_target_url_options)
        mail_answer_note_thread(@epic, @note, note_thread_options(reason))
      end
    end
  end
end
