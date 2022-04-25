# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210910094600_add_namespace_ancestry_ids_to_issues_mapping.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe AddNamespaceAncestryIdsToIssuesMapping do
  it_behaves_like 'a deprecated Advanced Search migration', 20210910094600
end
