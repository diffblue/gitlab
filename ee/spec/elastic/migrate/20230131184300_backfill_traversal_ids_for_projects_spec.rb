# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230131184300_backfill_traversal_ids_for_projects.rb')

RSpec.describe BackfillTraversalIdsForProjects, :elastic_delete_by_query, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20230131184300
end
