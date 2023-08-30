# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::LfsObjectRegistry, :geo, type: :model, feature_category: :geo_replication do
  let_it_be(:registry) { build(:geo_lfs_object_registry) }

  specify 'factory is valid' do
    expect(registry).to be_valid
  end

  include_examples 'a Geo framework registry'
  include_examples 'a Geo searchable registry'

  describe 'scopes' do
    describe '.for_synced_lfs_objects' do
      let_it_be(:registry2) { create(:geo_lfs_object_registry, :synced) }
      let_it_be(:registry3) { create(:geo_lfs_object_registry, :failed) }
      let_it_be(:registry4) { create(:geo_lfs_object_registry, :synced) }
      let_it_be(:registry5) { create(:geo_lfs_object_registry) }
      let_it_be(:registry6) { create(:geo_lfs_object_registry, :started) }

      let(:lfs_object_ids) do
        [
          registry2.lfs_object_id,
          registry3.lfs_object_id,
          registry4.lfs_object_id
        ]
      end

      it 'returns synced lfs object registries' do
        expect(described_class.for_synced_lfs_objects(lfs_object_ids)).to match_array([registry2, registry4])
      end
    end
  end

  describe '.oids_synced' do
    let_it_be(:registry2) { create(:geo_lfs_object_registry, :synced) }
    let_it_be(:registry3) { create(:geo_lfs_object_registry, :failed) }
    let_it_be(:registry4) { create(:geo_lfs_object_registry, :synced) }
    let_it_be(:registry5) { create(:geo_lfs_object_registry) }

    context 'when all given oids are synced' do
      let(:oids_input) do
        [
          registry2.lfs_object.oid,
          registry4.lfs_object.oid
        ]
      end

      it 'returns true' do
        expect(described_class.oids_synced?(oids_input)).to be(true)
      end
    end

    context 'when not all given oids are synced' do
      let(:oids_input) do
        [
          registry2.lfs_object.oid,
          registry4.lfs_object.oid,
          registry5.lfs_object.oid
        ]
      end

      it 'returns false' do
        expect(described_class.oids_synced?(oids_input)).to be(false)
      end
    end

    context 'when a given oid is unknown (e.g. there is high DB replication lag)' do
      let(:oids_input) do
        [
          registry2.lfs_object.oid,
          registry4.lfs_object.oid,
          'unknown_oid'
        ]
      end

      it 'returns false' do
        expect(described_class.oids_synced?(oids_input)).to be(false)
      end
    end
  end
end
