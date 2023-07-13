# frozen_string_literal: true

module Vulnerabilities
  class Remediation < ApplicationRecord
    include EachBatch
    include FileStoreMounter
    include ShaAttribute

    self.table_name = 'vulnerability_remediations'

    sha_attribute :checksum

    belongs_to :project, optional: false

    has_many :finding_remediations, class_name: 'Vulnerabilities::FindingRemediation', inverse_of: :remediation, foreign_key: 'vulnerability_remediation_id'
    has_many :findings, through: :finding_remediations

    mount_file_store_uploader AttachmentUploader

    validates :summary, presence: true, length: { maximum: 200 }
    validates :file, presence: true
    validates :checksum, presence: true

    scope :by_checksum, -> (checksum) { where(checksum: checksum) }

    def diff
      @diff ||= file.read
    end

    def retrieve_upload(_identifier, paths)
      Upload.find_by(model: self, path: paths)
    end
  end
end
