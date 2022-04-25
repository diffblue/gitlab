# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210813134600_add_namespace_ancestry_to_issues_mapping.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe AddNamespaceAncestryToIssuesMapping do
  it_behaves_like 'a deprecated Advanced Search migration', 20210813134600
end
