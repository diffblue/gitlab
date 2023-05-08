# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20221018125700_create_user_index.rb')

RSpec.describe CreateUserIndex, feature_category: :global_search do
  it_behaves_like 'a deprecated Advanced Search migration', 20221018125700
end
