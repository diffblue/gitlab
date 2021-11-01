# rubocop:todo Naming/FileName
# Upstream issue: https://github.com/rubocop/rubocop/issues/10221
# Upstream fix PR: https://github.com/rubocop/rubocop/pull/10223

# frozen_string_literal: true

module Gitlab
  module SPDX
    License = Struct.new(:id, :name, :deprecated, keyword_init: true)
  end
end
