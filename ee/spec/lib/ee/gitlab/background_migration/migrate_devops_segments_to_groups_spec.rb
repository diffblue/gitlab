# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateDevopsSegmentsToGroups, schema: 20210301200959 do
  let(:segments_table) { table(:analytics_devops_adoption_segments) }
  let(:selections_table) { table(:analytics_devops_adoption_segment_selections) }
  let(:namespaces_table) { table(:namespaces) }
  let(:namespace) { namespaces_table.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:namespace2) { namespaces_table.create!(name: 'gitlab-test', path: 'gitlab-test') }

  let!(:single_group_segment) do
    segments_table.create!.tap do |segment|
      selections_table.create!(group_id: namespace.id, segment_id: segment.id)
    end
  end

  let!(:multiple_groups_segment) do
    segments_table.create!.tap do |segment|
      selections_table.create!(group_id: namespace.id, segment_id: segment.id)
      selections_table.create!(group_id: namespace2.id, segment_id: segment.id)
    end
  end

  let!(:empty_segment) do
    segments_table.create!
  end

  describe '#perform' do
    it 'removes empty segments' do
      expect { subject.perform }.to change { segments_table.where(id: empty_segment.id).exists? }.to(false)
    end

    it 'sets namespace id for segments with single group' do
      expect do
        subject.perform
        single_group_segment.reload
      end.to change { single_group_segment.namespace_id }.from(nil).to(namespace.id)
    end

    it 'creates segment with namespace_id for each unique group across all selections' do
      expect do
        subject.perform
      end.to change { segments_table.where(namespace_id: [namespace.id, namespace2.id]).count }.from(0).to(2)
    end

    it 'schedules data calculation for fresh segments' do
      expect(Analytics::DevopsAdoption::CreateSnapshotWorker).to receive(:perform_in).with(kind_of(Integer), kind_of(Integer))

      subject.perform
    end

    it 'removes old multi-group segment' do
      expect { subject.perform }.to change { segments_table.where(id: multiple_groups_segment.id).exists? }.to(false)
    end

    context 'with duplicated segments' do
      let!(:single_group_segment_duplicate) do
        segments_table.create!.tap do |segment|
          selections_table.create!(group_id: namespace.id, segment_id: segment.id)
        end
      end

      it 'removes duplicated segments' do
        expect { subject.perform }.to change { segments_table.where(id: single_group_segment_duplicate).exists? }.to(false)
      end
    end
  end
end
