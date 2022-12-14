# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe FixStateColumnInLfsObjectRegistry, :geo, feature_category: :geo_replication do
  let(:registry) { table(:lfs_object_registry) }

  before do
    registry.create!(lfs_object_id: 1, state: 0, success: false)
    registry.create!(lfs_object_id: 2, state: 0, success: true)
    registry.create!(lfs_object_id: 3, state: 1, success: false)
    registry.create!(lfs_object_id: 4, state: 2, success: true)
    registry.create!(lfs_object_id: 5, state: 3, success: false)
  end

  it 'correctly sets registry state value' do
    pending_registries = registry.where(state: 0)
    synced_registries  = registry.where(state: 2)

    expect(pending_registries.pluck(:lfs_object_id)).to contain_exactly(1, 2)
    expect(synced_registries.pluck(:lfs_object_id)).to contain_exactly(4)

    migrate!

    expect(pending_registries.pluck(:lfs_object_id)).to contain_exactly(1)
    expect(synced_registries.pluck(:lfs_object_id)).to contain_exactly(2, 4)
  end
end
