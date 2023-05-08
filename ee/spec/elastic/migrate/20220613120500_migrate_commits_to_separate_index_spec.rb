# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20220613120500_migrate_commits_to_separate_index.rb')

RSpec.describe MigrateCommitsToSeparateIndex, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20220613120500
end
