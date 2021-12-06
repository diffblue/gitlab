# frozen_string_literal: true

module EE
  module BlobPresenter
    def code_owners
      ::Gitlab::CodeOwners.for_blob(project, blob)
    end
  end
end
