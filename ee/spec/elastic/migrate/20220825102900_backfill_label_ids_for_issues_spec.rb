# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20220825102900_backfill_label_ids_for_issues.rb')

RSpec.describe BackfillLabelIdsForIssues, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20220825102900
end
