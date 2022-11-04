# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/schema_change_methods_no_post'

RSpec.describe RuboCop::Cop::Migration::SchemaChangeMethodsNoPost do
  before do
    allow(cop).to receive(:time_enforced?).and_return true
  end

  it "does not allow 'add_column' to be called" do
    expect_offense(<<~CODE)
      add_column
      ^^^^^^^^^^ This method may not be used in post migrations.
    CODE
  end

  it "does not allow 'create_table' to be called" do
    expect_offense(<<~CODE)
      create_table
      ^^^^^^^^^^^^ This method may not be used in post migrations.
    CODE
  end
end
