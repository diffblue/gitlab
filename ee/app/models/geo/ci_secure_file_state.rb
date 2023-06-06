# frozen_string_literal: true
module Geo
  class CiSecureFileState < Ci::ApplicationRecord
    include ::Geo::VerificationStateDefinition

    self.primary_key = :ci_secure_file_id
    self.table_name = :ci_secure_file_states

    belongs_to :ci_secure_file, inverse_of: :ci_secure_file_state, class_name: 'Ci::SecureFile'

    validates :verification_state, :ci_secure_file, presence: true
  end
end
