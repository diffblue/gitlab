# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210510113500_delete_merge_requests_from_original_index.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe DeleteMergeRequestsFromOriginalIndex do
  it_behaves_like 'a deprecated Advanced Search migration', 20210510113500
end
