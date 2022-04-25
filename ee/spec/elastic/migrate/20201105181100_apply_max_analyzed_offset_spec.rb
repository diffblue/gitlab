# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20201105181100_apply_max_analyzed_offset.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe ApplyMaxAnalyzedOffset do
  it_behaves_like 'a deprecated Advanced Search migration', 20201105181100
end
