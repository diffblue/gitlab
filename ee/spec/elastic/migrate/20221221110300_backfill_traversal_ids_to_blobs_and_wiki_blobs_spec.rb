# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20221221110300_backfill_traversal_ids_to_blobs_and_wiki_blobs.rb')

RSpec.describe BackfillTraversalIdsToBlobsAndWikiBlobs, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20221221110300
end
