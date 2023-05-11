# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230426195404_add_hidden_to_merge_requests.rb')

RSpec.describe AddHiddenToMergeRequests, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230426195404 }

  include_examples 'migration adds mapping'
end
