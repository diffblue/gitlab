# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210910100000_redo_backfill_namespace_ancestry_ids_for_issues.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe RedoBackfillNamespaceAncestryIdsForIssues do
  it_behaves_like 'a deprecated Advanced Search migration', 20210910100000
end
