# frozen_string_literal: true

module Groups
  class SshCertificate < ApplicationRecord
    include ShaAttribute

    sha256_attribute :fingerprint

    self.table_name = :group_ssh_certificates

    belongs_to :group, foreign_key: :namespace_id, inverse_of: :ssh_certificates

    validates :group, presence: true
    validates :title, presence: true, length: { maximum: 255 }
    validates :key, presence: true, length: { maximum: 512.kilobytes }
    validates :fingerprint,
      presence: true,
      uniqueness: { message: ->(_, _) {
                               _('must be unique. This CA has already been configured for another namespace.')
                             } }
  end
end
