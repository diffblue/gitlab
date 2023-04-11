# frozen_string_literal: true

RSpec.shared_examples 'migration backfills fields' do
  let(:migration) { described_class.new(version) }
  let(:klass) { objects.first.class }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    set_elasticsearch_migration_to(version, including: false)

    # ensure objects are indexed
    objects

    ensure_elasticsearch_index!
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration).to be_batched
      expect(migration.throttle_delay).to eq(expected_throttle_delay)
      expect(migration.batch_size).to eq(expected_batch_size)
    end
  end

  describe '.migrate' do
    subject { migration.migrate }

    context 'when migration is already completed' do
      it 'does not modify data' do
        expect(::Elastic::ProcessInitialBookkeepingService).not_to receive(:track!)

        subject
      end
    end

    context 'migration process' do
      before do
        remove_field_from_objects(objects)
      end

      it 'updates all documents' do
        # track calls are batched in groups of 100
        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).once.and_call_original do |*tracked_refs|
          expect(tracked_refs.count).to eq(3)
        end

        subject

        ensure_elasticsearch_index!

        expect(migration.completed?).to be_truthy
      end

      it 'only updates documents missing a field', :aggregate_failures do
        object = objects.first
        add_field_for_objects(objects[1..])

        expected = [Gitlab::Elastic::DocumentReference.new(klass, object.id, object.es_id, object.es_parent)]
        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).with(*expected).once.and_call_original

        subject

        ensure_elasticsearch_index!

        expect(migration.completed?).to be_truthy
      end

      it 'processes in batches', :aggregate_failures do
        allow(migration).to receive(:batch_size).and_return(2)
        allow(migration).to receive(:update_batch_size).and_return(1)

        expect(::Elastic::ProcessInitialBookkeepingService).to receive(:track!).exactly(3).times.and_call_original

        # cannot use subject in spec because it is memoized
        migration.migrate

        ensure_elasticsearch_index!

        migration.migrate

        ensure_elasticsearch_index!

        expect(migration.completed?).to be_truthy
      end
    end
  end

  describe '.completed?' do
    context 'when documents are missing field' do
      before do
        remove_field_from_objects(objects)
      end

      specify { expect(migration).not_to be_completed }
    end

    context 'when no documents are missing field' do
      specify { expect(migration).to be_completed }
    end
  end

  private

  def add_field_for_objects(objects)
    source_script = expected_fields.map do |field_name, _|
      "ctx._source['#{field_name}'] = params.#{field_name};"
    end.join

    script =  {
      source: source_script,
      lang: "painless",
      params: expected_fields
    }

    update_by_query(objects, script)
  end

  def remove_field_from_objects(objects)
    source_script = expected_fields.map do |field_name, _|
      "ctx._source.remove('#{field_name}');"
    end.join

    script = {
      source: source_script
    }

    update_by_query(objects, script)
  end

  def update_by_query(objects, script)
    object_ids = objects.map(&:id)

    client = klass.__elasticsearch__.client
    client.update_by_query({
                             index: klass.__elasticsearch__.index_name,
                             wait_for_completion: true, # run synchronously
                             refresh: true, # make operation visible to search
                             body: {
                               script: script,
                               query: {
                                 bool: {
                                   must: [
                                     {
                                       terms: {
                                         id: object_ids
                                       }
                                     }
                                   ]
                                 }
                               }
                             }
                           })
  end
end

RSpec.shared_examples 'migration adds mapping' do
  let(:migration) { described_class.new(version) }
  let(:helper) { Gitlab::Elastic::Helper.new }

  before do
    allow(migration).to receive(:helper).and_return(helper)
  end

  describe '.migrate' do
    subject { migration.migrate }

    context 'when migration is already completed' do
      it 'does not modify data' do
        expect(helper).not_to receive(:update_mapping)

        subject
      end
    end

    context 'migration process' do
      before do
        allow(helper).to receive(:get_mapping).and_return({})
      end

      it 'updates the issues index mappings' do
        expect(helper).to receive(:update_mapping)

        subject
      end
    end
  end

  describe '.completed?' do
    context 'mapping has been updated' do
      specify { expect(migration).to be_completed }
    end

    context 'mapping has not been updated' do
      before do
        allow(helper).to receive(:get_mapping).and_return({})
      end

      specify { expect(migration).not_to be_completed }
    end
  end
end

RSpec.shared_examples 'a deprecated Advanced Search migration' do |version|
  subject { described_class.new(version) }

  describe '#migrate' do
    it 'logs a message and halts the migration' do
      expect(subject).to receive(:log).with(/has been deleted in the last major version upgrade/)
      expect(subject).to receive(:fail_migration_halt_error!).and_return(true)

      subject.migrate
    end
  end

  describe '#completed?' do
    it 'returns false' do
      expect(subject.completed?).to be false
    end
  end

  describe '#obsolete?' do
    it 'returns true' do
      expect(subject.obsolete?).to be true
    end
  end
end
