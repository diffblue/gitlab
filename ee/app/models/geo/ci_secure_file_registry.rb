# frozen_string_literal: true

module Geo
  class CiSecureFileRegistry < Geo::BaseRegistry
    include ::Geo::ReplicableRegistry
    include ::Geo::VerifiableRegistry

    MODEL_CLASS = ::Ci::SecureFile
    MODEL_FOREIGN_KEY = :ci_secure_file_id

    belongs_to :ci_secure_file, class_name: 'Ci::SecureFile'
  end
end
