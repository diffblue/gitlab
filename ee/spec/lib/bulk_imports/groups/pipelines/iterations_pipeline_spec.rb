# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::IterationsPipeline do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:timestamp) { Time.new(2020, 01, 01).utc }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }

  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path',
      destination_slug: 'My-Destination-Group',
      destination_namespace: group.full_path,
      group: group
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

  subject { described_class.new(context) }

  before do
    stub_licensed_features(iterations: true)
    group.add_owner(user)
  end

  describe '#run' do
    it 'imports group iterations' do
      first_page = extracted_data(title: 'iteration1', has_next_page: true)
      last_page = extracted_data(title: 'iteration2', start_date: Date.today + 2.days)

      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        allow(extractor)
          .to receive(:extract)
          .and_return(first_page, last_page)
      end

      expect { subject.run }.to change(Iteration, :count).by(2)

      expect(group.iterations.pluck(:title)).to contain_exactly('iteration1', 'iteration2')

      iteration = group.iterations.last

      expect(iteration.description).to eq('desc')
      expect(iteration.state).to eq('upcoming')
      expect(iteration.start_date).to eq(Date.today + 2.days)
      expect(iteration.due_date).to eq(Date.today + 3.days)
      expect(iteration.created_at).to eq(timestamp)
      expect(iteration.updated_at).to eq(timestamp)
    end
  end

  describe '#load' do
    it 'creates the iteration' do
      data = iteration_data('iteration')

      expect { subject.load(context, data) }.to change(Iteration, :count).by(1)
    end

    context 'when user is not authorized to create the milestone' do
      before do
        allow(user).to receive(:can?).with(:admin_iteration, group).and_return(false)
      end

      it 'raises NotAllowedError' do
        data = extracted_data(title: 'iteration', has_next_page: false)

        expect { subject.load(context, data) }.to raise_error(::BulkImports::Pipeline::NotAllowedError)
      end
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.get_extractor)
        .to eq(
          klass: BulkImports::Common::Extractors::GraphqlExtractor,
          options: {
            query: BulkImports::Groups::Graphql::GetIterationsQuery
          }
        )
    end

    it 'has transformers' do
      expect(described_class.transformers)
        .to contain_exactly(
          { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil }
        )
    end
  end

  def iteration_data(title, start_date: Date.today)
    {
      'title' => title,
      'description' => 'desc',
      'state' => 'upcoming',
      'start_date' => start_date,
      'due_date' => start_date + 1.day,
      'created_at' => timestamp.to_s,
      'updated_at' => timestamp.to_s
    }
  end

  def extracted_data(title:, start_date: Date.today, has_next_page: false)
    page_info = {
      'has_next_page' => has_next_page,
      'next_page' => has_next_page ? 'cursor' : nil
    }

    BulkImports::Pipeline::ExtractedData.new(
      data: iteration_data(title, start_date: start_date),
      page_info: page_info
    )
  end
end
