# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20220119120500_populate_commit_permissions_in_main_index.rb')

RSpec.describe PopulateCommitPermissionsInMainIndex, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20220119120500
end
