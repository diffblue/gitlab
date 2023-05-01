# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20220824133000_add_hidden_to_issues.rb')

RSpec.describe AddHiddenToIssues, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20220824133000
end
