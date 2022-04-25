# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20201116142400_add_new_data_to_issues_documents.rb')
require File.expand_path('ee/spec/elastic/migrate/migration_shared_examples.rb')

RSpec.describe AddNewDataToIssuesDocuments do
  it_behaves_like 'a deprecated Advanced Search migration', 20201116142400
end
