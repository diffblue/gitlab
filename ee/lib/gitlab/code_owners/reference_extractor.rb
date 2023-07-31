# frozen_string_literal: true

# This class extracts all references found in a piece
# it's either @name or email address

module Gitlab
  module CodeOwners
    class ReferenceExtractor
      # Not using `Devise.email_regexp` to filter out any chars that an email
      # does not end with and not pinning the email to a start of end of a string.
      EMAIL_REGEXP = /(?<email>([^@\s]+@[^@\s]+(?<!\W)))/
      NAME_REGEXP = User.reference_pattern

      def initialize(text)
        # EE passes an Array to `text` in a few places, so we want to support both
        # here.
        @text = Array(text).join(' ')
      end

      def names
        matches[:names]
      end

      def emails
        matches[:emails]
      end

      def references
        return [] if @text.blank?

        @references ||= matches.values.flatten.uniq
      end

      private

      def matches
        @matches ||= {
          emails: @text.scan(EMAIL_REGEXP).flatten.uniq,
          names: @text.scan(NAME_REGEXP).flatten.uniq
        }
      end
    end
  end
end
