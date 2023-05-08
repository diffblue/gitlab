# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20220824123000_add_label_ids_and_schema_version_to_issues_mapping.rb')

RSpec.describe AddLabelIdsAndSchemaVersionToIssuesMapping, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20220824123000
end
