# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUserNamespace do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }

  before do
    namespaces.create!(id: 1, name: 'test1', path: 'test1', type: nil)
    namespaces.create!(id: 2, name: 'test2', path: 'test2', type: 'User')
    namespaces.create!(id: 3, name: 'test3', path: 'test3', type: 'Group')
    namespaces.create!(id: 4, name: 'test4', path: 'test4', type: nil)
    namespaces.create!(id: 11, name: 'test11', path: 'test11', type: nil)
  end

  it 'backfills `type_new` for the selected records' do
    queries = ActiveRecord::QueryRecorder.new do
      migration.perform(1, 10)
    end

    expect(queries.count).to be(1)
    expect(Namespace.where(type: 'User').count).to eq 3
  end
end
