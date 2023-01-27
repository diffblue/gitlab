# frozen_string_literal: true

module Zoekt
  class Shard < ApplicationRecord
    def self.table_name_prefix
      'zoekt_'
    end

    has_many :indexed_namespaces, foreign_key: :zoekt_shard_id, inverse_of: :shard
  end
end
