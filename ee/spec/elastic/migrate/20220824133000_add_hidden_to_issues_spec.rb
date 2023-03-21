# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20220824133000_add_hidden_to_issues.rb')

RSpec.describe AddHiddenToIssues, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230208195404 }

  include_examples 'migration adds mapping'
end
