# frozen_string_literal: true

module Mutations
  module Notes
    class Base < BaseMutation
      QUICK_ACTION_ONLY_WARNING = <<~NB
        If the body of the Note contains only quick actions,
        the Note will be destroyed during an update, and no Note will be
        returned.
      NB

      field :note,
            Types::Notes::NoteType,
            null: true,
            description: 'Note after mutation.'

      private

      def find_object(id:)
        GitlabSchema.find_by_gid(id)
      end

      def verify_notes_support!(noteable)
        return if noteable&.supports_notes?

        raise Gitlab::Graphql::Errors::ResourceNotAvailable, "Notes are not supported"
      end
    end
  end
end
