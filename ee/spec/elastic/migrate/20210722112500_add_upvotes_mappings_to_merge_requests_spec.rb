# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210722112500_add_upvotes_mappings_to_merge_requests.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe AddUpvotesMappingsToMergeRequests do
  it_behaves_like 'a deprecated Advanced Search migration', 20210722112500
end
