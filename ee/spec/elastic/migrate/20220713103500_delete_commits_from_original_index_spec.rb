# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20220713103500_delete_commits_from_original_index.rb')

RSpec.describe DeleteCommitsFromOriginalIndex, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20220713103500
end
