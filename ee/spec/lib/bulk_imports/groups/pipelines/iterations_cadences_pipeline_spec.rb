# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::IterationsCadencesPipeline, feature_category: :importers do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:bulk_import) { create(:bulk_import, user: user) }
  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }
  let(:entity) do
    create(
      :bulk_import_entity,
      group: group,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Group',
      destination_namespace: group.full_path
    )
  end

  let(:object) do
    {
      'title' => 'title',
      'start_date' => '2022-01-01',
      'active' => true,
      'roll_over' => false,
      'description' => 'cadence description',
      'iterations' => [
        {
          'iid' => 1,
          'start_date' => '2022-01-01',
          'due_date' => '2022-02-02',
          'description' => 'iteration description',
          'sequence' => 1
        }
      ]
    }
  end

  before do
    group.add_owner(user)

    allow_next_instance_of(BulkImports::Common::Extractors::NdjsonExtractor) do |extractor|
      allow(extractor).to receive(:extract).and_return(BulkImports::Pipeline::ExtractedData.new(data: [[object, 0]]))
    end
  end

  subject { described_class.new(context) }

  describe '#run' do
    it 'imports iteration cadences', :aggregate_failures do
      expect { subject.run }.to change(Iterations::Cadence, :count).by(1)

      cadence = group.iterations_cadences.first

      expect(cadence.title).to eq('title')
      expect(cadence.description).to eq('cadence description')
      expect(cadence.automatic).to eq(false)
      expect(cadence.roll_over).to eq(false)
    end

    it 'imports iterations within cadences', :aggregate_failures do
      expect { subject.run }.to change(Iteration, :count).by(1)

      iteration = group.iterations_cadences.first.iterations.first

      expect(iteration.iid).to eq(1)
      expect(iteration.title).to be_nil
      expect(iteration.state).to eq('closed')
      expect(iteration.description).to eq('iteration description')
      expect(iteration.sequence).to eq(1)
    end
  end

  describe '#load' do
    context 'when iterations cadence is not persisted' do
      it 'saves the milestone' do
        cadence = build(:iterations_cadence, group: group)

        expect_next_instance_of(Gitlab::ImportExport::Base::RelationObjectSaver) do |saver|
          expect(saver).to receive(:execute)
        end

        subject.load(context, cadence)
      end
    end

    context 'when iterations cadence is missing' do
      it 'returns' do
        expect(subject.load(context, nil)).to be_nil
      end
    end
  end
end
