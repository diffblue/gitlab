# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20210112165500_delete_issues_from_original_index.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe DeleteIssuesFromOriginalIndex do
  it_behaves_like 'a deprecated Advanced Search migration', 20210112165500
end
