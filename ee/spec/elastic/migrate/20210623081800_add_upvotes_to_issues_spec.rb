# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210623081800_add_upvotes_to_issues.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe AddUpvotesToIssues do
  it_behaves_like 'a deprecated Advanced Search migration', 20210623081800
end
