# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230208100000_reindex_users.rb')

RSpec.describe ReindexUsers, :elastic, :sidekiq_inline, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20230208100000
end
