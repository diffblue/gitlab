# frozen_string_literal: true

RSpec.shared_examples 'a Geo bulk mark update batch worker' do
  describe '#perform' do
    let(:registry) { build_stubbed(registry_factory) }

    it 'calls the bulk_mark_update_one_batch! method' do
      allow_next_instance_of(service) do |instance|
        allow(instance).to receive(:remaining_batches_to_bulk_mark_update).and_return(1)
      end

      expect_any_instance_of(service) do |instance|
        expect(instance).to receive(:bulk_mark_update_one_batch!).with(registry_class)
      end

      worker.perform(registry_class.name)
    end
  end

  describe '.perform_with_capacity' do
    it 'resets the Redis cursor to zero' do
      expect_any_instance_of(service) do |instance|
        expect(instance).to receive(:set_bulk_mark_update_cursor).with(0).and_call_original
      end

      described_class.perform_with_capacity(registry_class.name)
    end
  end
end
