# frozen_string_literal: true
module Geo
  class SecureFileState < Ci::ApplicationRecord
    include EachBatch
    include ::Geo::VerificationStateDefinition

    self.primary_key = :ci_secure_file_id

    belongs_to :ci_secure_file, inverse_of: :ci_secure_file_state, class_name: 'Ci::SecureFile'

    validates :verification_failure, length: { maximum: 255 }
    validates :verification_state, :ci_secure_file, presence: true
  end
end
