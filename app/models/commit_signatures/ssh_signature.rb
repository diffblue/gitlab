# frozen_string_literal: true

module CommitSignatures
  class SshSignature < ApplicationRecord
    include CommitSignature

    belongs_to :key
  end
end
