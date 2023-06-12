# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230613555555_add_schema_version_to_commits.rb')

RSpec.describe AddSchemaVersionToCommits, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230613555555 }

  include_examples 'migration adds mapping'
end
