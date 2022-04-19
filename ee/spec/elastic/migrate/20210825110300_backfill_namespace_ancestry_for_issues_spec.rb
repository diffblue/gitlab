# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210825110300_backfill_namespace_ancestry_for_issues.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe BackfillNamespaceAncestryForIssues do
  it_behaves_like 'a deprecated Advanced Search migration', 20210825110300
end
