# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230209195404_backfill_hidden_on_issues.rb')

RSpec.describe BackfillHiddenOnIssues, :elastic_delete_by_query, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20230209195404
end
