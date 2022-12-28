# frozen_string_literal: true

module Elastic
  class GroupIndexStatus < ApplicationRecord
    include ::ShaAttribute

    self.table_name = 'elastic_group_index_statuses'
    self.primary_key = :namespace_id

    sha_attribute :last_wiki_commit

    belongs_to :group, foreign_key: :namespace_id, inverse_of: :index_status

    validates :namespace_id, presence: true
  end
end
