# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20220512150000_pause_indexing_for_unsupported_es_versions.rb')

RSpec.describe PauseIndexingForUnsupportedEsVersions, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20220512150000
end
