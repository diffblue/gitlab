# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230320011400_add_hashed_root_namespace_id_to_commits.rb')

RSpec.describe AddHashedRootNamespaceIdToCommits, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230320011400 }

  include_examples 'migration adds mapping'
end
