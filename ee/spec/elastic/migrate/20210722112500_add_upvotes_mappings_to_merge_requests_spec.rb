# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20210722112500_add_upvotes_mappings_to_merge_requests.rb')

RSpec.describe AddUpvotesMappingsToMergeRequests, :elastic, :sidekiq_inline do
  let(:version) { 20210722112500 }

  include_examples 'migration adds mapping'
end
