# frozen_string_literal: true

RSpec.shared_examples 'is a Geo batcher' do
  include EE::GeoHelpers

  describe '#next_range!' do
    let(:batcher) { described_class.new(destination_class, key: key, batch_size: batch_size) }
    let(:source_foreign_key) { batcher.send(:source_foreign_key) }
    let(:key) { 'looping_batcher_spec' }
    let(:batch_size) { 2 }

    subject { batcher.next_range! }

    context 'when there are no records' do
      it { is_expected.to be_nil }
    end

    context 'when there are no records but there are orphaned destination_records' do
      let!(:destination_records) { create_list(destination_class_factory, 3) }

      context 'when it has never been called before' do
        it { is_expected.to be_a Range }

        it 'starts from the beginning' do
          expect(subject.first).to eq(1)
        end

        it 'ends at a full batch' do
          expect(subject.last).to eq(destination_records.second.public_send(source_foreign_key))
        end

        context 'when the batch size is greater than the number of destination_records' do
          let(:batch_size) { 5 }

          it 'ends at the last ID' do
            expect(subject.last).to eq(destination_records.last.public_send(source_foreign_key))
          end
        end
      end

      context 'when it was called before' do
        context 'when the previous batch included the end of the table' do
          before do
            described_class.new(destination_class, key: key, batch_size: destination_class.count).next_range!
          end

          it 'starts from the beginning' do
            expect(subject).to eq(1..destination_records.second.public_send(source_foreign_key))
          end
        end

        context 'when the previous batch did not include the end of the table' do
          before do
            described_class.new(destination_class, key: key, batch_size: destination_class.count - 1).next_range!
          end

          it 'starts after the previous batch' do
            expect(subject).to eq(destination_records.last.public_send(source_foreign_key)..destination_records.last.public_send(source_foreign_key))
          end
        end

        context 'if cache is cleared' do
          before do
            described_class.new(destination_class, key: key, batch_size: batch_size).next_range!
          end

          it 'starts from the beginning' do
            Rails.cache.clear

            expect(subject).to eq(1..destination_records.second.public_send(source_foreign_key))
          end
        end
      end
    end

    context 'when there are records' do
      let!(:records) { create_list(source_class.underscore, 3) }

      context 'when it has never been called before' do
        it { is_expected.to be_a Range }

        it 'starts from the beginning' do
          expect(subject.first).to eq(1)
        end

        it 'ends at a full batch' do
          expect(subject.last).to eq(records.second.id)
        end

        context 'when the batch size is greater than the number of records' do
          let(:batch_size) { 5 }

          it 'ends at the last ID' do
            expect(subject.last).to eq(records.last.id)
          end
        end
      end

      context 'when it was called before' do
        context 'when the previous batch included the end of the table' do
          before do
            described_class.new(destination_class, key: key, batch_size: source_class.count).next_range!
          end

          it 'starts from the beginning' do
            expect(subject).to eq(1..records.second.id)
          end
        end

        context 'when the previous batch did not include the end of the table' do
          before do
            described_class.new(destination_class, key: key, batch_size: source_class.count - 1).next_range!
          end

          it 'starts after the previous batch' do
            expect(subject).to eq(records.last.id..records.last.id)
          end
        end

        context 'if cache is cleared' do
          before do
            described_class.new(destination_class, key: key, batch_size: batch_size).next_range!
          end

          it 'starts from the beginning' do
            Rails.cache.clear

            expect(subject).to eq(1..records.second.id)
          end
        end
      end
    end

    context 'when there are records and orphaned destination_records with foreign key greater than last record id' do
      let!(:records) { create_list(source_class.underscore, 3) }
      let(:orphaned_destination_foreign_key_id) { records.last.id }
      let!(:destination) { create(destination_class_factory, source_foreign_key => orphaned_destination_foreign_key_id) }

      before do
        source_class.where(id: orphaned_destination_foreign_key_id).delete_all
      end

      context 'when it has never been called before' do
        it { is_expected.to be_a Range }

        it 'starts from the beginning' do
          expect(subject.first).to eq(1)
        end

        it 'ends at the last destination foreign key ID' do
          expect(subject.last).to eq(orphaned_destination_foreign_key_id)
        end
      end

      context 'when it was called before' do
        before do
          described_class.new(destination_class, key: key, batch_size: batch_size).next_range!
        end

        it 'starts from the beginning' do
          expect(subject).to eq(1..orphaned_destination_foreign_key_id)
        end

        context 'if cache is cleared' do
          it 'starts from the beginning' do
            Rails.cache.clear

            expect(subject).to eq(1..orphaned_destination_foreign_key_id)
          end
        end
      end
    end
  end
end
