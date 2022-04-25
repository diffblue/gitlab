# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210429154500_migrate_merge_requests_to_separate_index.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe MigrateMergeRequestsToSeparateIndex do
  it_behaves_like 'a deprecated Advanced Search migration', 20210429154500
end
