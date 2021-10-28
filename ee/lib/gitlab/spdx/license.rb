# rubocop:disable Naming/FileName
# frozen_string_literal: true

module Gitlab
  module SPDX
    License = Struct.new(:id, :name, :deprecated, keyword_init: true)
  end
end

# rubocop:enable Naming/FileName
