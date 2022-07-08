# frozen_string_literal: true
module Vulnerabilities
  class MergeRequestLink < ApplicationRecord
    self.table_name = 'vulnerability_merge_request_links'

    belongs_to :vulnerability
    belongs_to :merge_request
  end
end
