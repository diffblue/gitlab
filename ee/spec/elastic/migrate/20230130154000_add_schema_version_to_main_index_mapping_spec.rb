# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230130154000_add_schema_version_to_main_index_mapping.rb')

RSpec.describe AddSchemaVersionToMainIndexMapping, :elastic, :sidekiq_inline, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20230130154000
end
