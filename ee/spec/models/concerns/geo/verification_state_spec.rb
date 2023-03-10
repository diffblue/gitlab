# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::VerificationState, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let_it_be(:primary_node) { create(:geo_node, :primary) }
  let_it_be(:secondary_node) { create(:geo_node) }

  context 'for Model classes' do
    context 'when verification state is stored in the model table' do
      before(:all) do
        create_dummy_model_table
      end

      after(:all) do
        drop_dummy_model_table
      end

      before do
        stub_dummy_replicator_class
        stub_dummy_model_class
      end

      subject { DummyModel.new }

      context 'state machine' do
        context 'when failed' do
          before do
            subject.verification_started
            subject.verification_failed_with_message!('foo')
          end

          context 'and transitioning to pending' do
            it 'marks verification as pending' do
              subject.verification_pending!

              expect(subject.reload.verification_pending?).to be_truthy
            end

            it 'does not clear retry attributes' do
              subject.verification_pending!

              expect(subject.reload).to have_attributes(
                verification_state: DummyModel.verification_state_value(:verification_pending),
                verification_retry_count: 1,
                verification_retry_at: be_present
              )
            end
          end
        end
      end

      describe '.verification_pending_batch' do
        # Insert 2 records for a total of 3 with subject
        let!(:other_pending_records) do
          DummyModel.insert_all(
            [
              { verification_state: pending_value, verified_at: 7.days.ago },
              { verification_state: pending_value, verified_at: 6.days.ago }
            ], returning: [:id])
        end

        let(:pending_value) { DummyModel.verification_state_value(:verification_pending) }
        let(:other_pending_ids) { other_pending_records.map { |result| result['id'] } }

        before do
          subject.save!
        end

        it 'returns IDs of rows pending verification' do
          expect(subject.class.verification_pending_batch(batch_size: 3)).to include(subject.id)
        end

        it 'marks verification as started' do
          subject.class.verification_pending_batch(batch_size: 3)

          expect(subject.reload.verification_started?).to be_truthy
          expect(subject.verification_started_at).to be_present
        end

        it 'limits with batch_size and orders records by verified_at with NULLs first' do
          expected = [subject.id, other_pending_ids.first]

          # `match_array` instead of `eq` because the UPDATE query does not
          # guarantee that results are returned in the same order as the subquery
          # used to SELECT the correct batch.
          expect(subject.class.verification_pending_batch(batch_size: 2)).to match_array(expected)
        end

        context 'other verification states' do
          it 'does not include them' do
            subject.verification_started!

            expect(subject.class.verification_pending_batch(batch_size: 3)).not_to include(subject.id)

            subject.verification_succeeded_with_checksum!('foo', Time.current)

            expect(subject.class.verification_pending_batch(batch_size: 3)).not_to include(subject.id)

            subject.verification_started
            subject.verification_failed_with_message!('foo')

            expect(subject.class.verification_pending_batch(batch_size: 3)).not_to include(subject.id)
          end
        end
      end

      describe '.verification_failed_batch' do
        # Insert 2 records for a total of 3 with subject
        let!(:other_failed_records) do
          DummyModel.insert_all(
            [
              { verification_state: failed_value, verification_retry_at: 7.days.ago },
              { verification_state: failed_value, verification_retry_at: 6.days.ago }
            ], returning: [:id])
        end

        let(:failed_value) { DummyModel.verification_state_value(:verification_failed) }
        let(:other_failed_ids) { other_failed_records.map { |result| result['id'] } }

        before do
          subject.verification_started
          subject.verification_failed_with_message!('foo')
        end

        context 'with a failed record with retry due' do
          before do
            subject.update!(verification_retry_at: 1.minute.ago)
          end

          it 'returns IDs of rows pending verification' do
            expect(subject.class.verification_failed_batch(batch_size: 3)).to include(subject.id)
          end

          it 'marks verification as started' do
            subject.class.verification_failed_batch(batch_size: 3)

            expect(subject.reload.verification_started?).to be_truthy
            expect(subject.verification_started_at).to be_present
          end

          it 'limits with batch_size and orders records by verification_retry_at with NULLs first' do
            expected = other_failed_ids

            # `match_array` instead of `eq` because the UPDATE query does not
            # guarantee that results are returned in the same order as the subquery
            # used to SELECT the correct batch.
            expect(subject.class.verification_failed_batch(batch_size: 2)).to match_array(expected)
          end

          context 'other verification states' do
            it 'does not include them' do
              subject.verification_started!

              expect(subject.class.verification_failed_batch(batch_size: 5)).not_to include(subject.id)

              subject.verification_succeeded_with_checksum!('foo', Time.current)

              expect(subject.class.verification_failed_batch(batch_size: 5)).not_to include(subject.id)

              subject.verification_pending!

              expect(subject.class.verification_failed_batch(batch_size: 5)).not_to include(subject.id)
            end
          end
        end

        context 'when verification_retry_at is in the future' do
          it 'does not return the row' do
            subject.update!(verification_retry_at: 1.minute.from_now)

            expect(subject.class.verification_failed_batch(batch_size: 3)).not_to include(subject.id)
          end
        end
      end

      describe '.needs_verification' do
        it 'includes verification_pending' do
          subject.save!

          expect(subject.class.needs_verification).to include(subject)
        end

        it 'includes verification_failed and verification_retry_due' do
          subject.verification_started
          subject.verification_failed_with_message!('foo')
          subject.update!(verification_retry_at: 1.minute.ago)

          expect(subject.class.needs_verification).to include(subject)
        end

        it 'excludes verification_failed with future verification_retry_at' do
          subject.verification_started
          subject.verification_failed_with_message!('foo')
          subject.update!(verification_retry_at: 1.minute.from_now)

          expect(subject.class.needs_verification).not_to include(subject)
        end
      end

      describe '.needs_reverification' do
        before do
          stub_current_geo_node(primary_node)
        end

        let(:pending_value) { DummyModel.verification_state_value(:verification_pending) }
        let(:failed_value) { DummyModel.verification_state_value(:verification_failed) }
        let(:succeeded_value) { DummyModel.verification_state_value(:verification_succeeded) }

        it 'includes verification_succeeded with expired checksum' do
          DummyModel.insert_all(
            [
              { verification_state: succeeded_value, verified_at: 15.days.ago }
            ])

          expect(subject.class.needs_reverification.count).to eq 1
        end

        it 'excludes non-success verification states and fresh checksums' do
          DummyModel.insert_all(
            [
              { verification_state: pending_value, verified_at: 7.days.ago },
              { verification_state: failed_value, verified_at: 6.days.ago },
              { verification_state: succeeded_value, verified_at: 3.days.ago }
            ])

          expect(subject.class.needs_reverification.count).to eq 0
        end
      end

      describe '.reverify_batch' do
        let!(:other_verified_records) do
          DummyModel.insert_all(
            [
              { verification_state: succeeded_value, verified_at: 3.days.ago },
              { verification_state: succeeded_value, verified_at: 4.days.ago }
            ])
        end

        let(:succeeded_value) { DummyModel.verification_state_value(:verification_succeeded) }

        before do
          stub_current_geo_node(primary_node)

          subject.verification_started

          subject.verification_succeeded_with_checksum!('foo', Time.current)

          subject.update!(verified_at: 15.days.ago)
        end

        it 'sets pending status to records with outdated verification' do
          expect do
            expect(subject.class.reverify_batch(batch_size: 100)).to eq 1
          end.to change { subject.reload.verification_pending? }.to be_truthy
        end

        it 'limits the update with batch_size' do
          DummyModel.update_all(verified_at: 15.days.ago)

          expect(subject.class.reverify_batch(batch_size: 2)).to eq 2
          expect(DummyModel.verification_pending.count).to eq 2
        end
      end

      describe '.fail_verification_timeouts' do
        before do
          subject.verification_started!
        end

        context 'when verification has not timed out for a record' do
          it 'does not update verification state' do
            subject.update!(verification_started_at: (described_class::VERIFICATION_TIMEOUT - 1.minute).ago)

            DummyModel.fail_verification_timeouts

            expect(subject.reload.verification_started?).to be_truthy
          end
        end

        context 'when verification has timed out for a record' do
          it 'sets verification state to failed' do
            subject.update!(verification_started_at: (described_class::VERIFICATION_TIMEOUT + 1.minute).ago)

            DummyModel.fail_verification_timeouts

            expect(subject.reload.verification_failed?).to be_truthy
          end
        end
      end

      describe '#track_checksum_attempt!', :aggregate_failures do
        context 'when verification was not yet started' do
          it 'starts verification' do
            expect do
              subject.track_checksum_attempt! do
                'a_checksum_value'
              end
            end.to change { subject.verification_started_at }.from(nil)
          end

          it 'sets verification_succeeded' do
            expect do
              subject.track_checksum_attempt! do
                'a_checksum_value'
              end
            end.to change { subject.verification_succeeded? }.from(false).to(true)
          end
        end

        context 'when verification was started' do
          it 'does not update verification_started_at' do
            subject.verification_started!
            expected = subject.verification_started_at

            subject.track_checksum_attempt! do
              'a_checksum_value'
            end

            expect(subject.verification_started_at).to be_within(1.second).of(expected)
          end
        end

        it 'yields to the checksum calculation' do
          expect do |probe|
            subject.track_checksum_attempt!(&probe)
          end.to yield_with_no_args
        end

        context 'when an error occurs while yielding' do
          context 'when the record was failed' do
            it 'sets verification_failed and increments verification_retry_count' do
              subject.verification_failed_with_message!('foo')

              subject.track_checksum_attempt! do
                raise 'an error'
              end

              expect(subject.reload.verification_failed?).to be_truthy
              expect(subject.verification_retry_count).to eq(2)
            end
          end
        end

        context 'when the yielded block returns nil' do
          context 'when the record was pending' do
            it 'sets verification_failed and sets verification_retry_count to 1' do
              subject.track_checksum_attempt! { nil }

              expect(subject.reload.verification_failed?).to be_truthy
              expect(subject.verification_retry_count).to eq(1)
            end
          end

          context 'when the record was failed' do
            it 'sets verification_failed and increments verification_retry_count' do
              subject.verification_failed_with_message!('foo')

              subject.track_checksum_attempt! { nil }

              expect(subject.reload.verification_failed?).to be_truthy
              expect(subject.verification_retry_count).to eq(2)
            end
          end
        end
      end

      describe '#verification_succeeded_with_checksum!' do
        before do
          subject.verification_started!
        end

        context 'when the resource was updated during checksum calculation' do
          let(:calculation_started_at) { subject.verification_started_at - 1.second }

          it 'sets state to pending' do
            subject.verification_succeeded_with_checksum!('abc123', calculation_started_at)

            expect(subject.reload.verification_pending?).to be_truthy
          end
        end

        context 'when the resource was not updated during checksum calculation' do
          let(:calculation_started_at) { subject.verification_started_at + 1.second }

          it 'saves the checksum' do
            subject.verification_succeeded_with_checksum!('abc123', calculation_started_at)

            expect(subject.reload.verification_succeeded?).to be_truthy
            expect(subject.reload.verification_checksum).to eq('abc123')
            expect(subject.verified_at).not_to be_nil
          end
        end

        context 'primary node' do
          it 'calls replicator.handle_after_checksum_succeeded' do
            stub_current_geo_node(primary_node)

            expect(subject.replicator).to receive(:handle_after_checksum_succeeded)

            subject.verification_succeeded_with_checksum!('abc123', Time.current)
          end
        end

        context 'secondary node' do
          it 'does not call replicator.handle_after_checksum_succeeded' do
            stub_current_geo_node(secondary_node)

            expect(subject.replicator).not_to receive(:handle_after_checksum_succeeded)

            subject.verification_succeeded_with_checksum!('abc123', Time.current)
          end
        end
      end

      describe '#verification_failed_with_message!' do
        it 'saves the error message and increments retry counter' do
          error = double('error', message: 'An error message')

          subject.verification_started!
          subject.verification_failed_with_message!('Failure to calculate checksum', error)

          expect(subject.reload.verification_failed?).to be_truthy
          expect(subject.reload.verification_failure).to eq 'Failure to calculate checksum: An error message'
          expect(subject.verification_retry_count).to be 1
          expect(subject.verification_checksum).to be_nil
        end
      end

      describe '#verification_started!' do
        it 'flips the state to started state' do
          expect { subject.verification_started! }.to change { subject.verification_state }.from(0).to(1)
        end
      end
    end

    context 'when verification state is stored in a separate table' do
      before(:all) do
        create_dummy_model_with_separate_state_table
      end

      after(:all) do
        drop_dummy_model_with_separate_state_table
      end

      before do
        stub_dummy_replicator_class(model_class: 'TestDummyModelWithSeparateState')
        stub_dummy_model_with_separate_state_class
      end

      subject { TestDummyModelWithSeparateState.new }

      describe '.fail_verification_timeouts' do
        it 'sets verification state to failed' do
          state = subject.verification_state_object
          state.update!(verification_started_at: (described_class::VERIFICATION_TIMEOUT + 1.minute).ago, verification_state: 1)

          TestDummyModelWithSeparateState.fail_verification_timeouts

          expect(subject.reload.verification_failed?).to be_truthy
        end
      end

      describe '#verification_started!' do
        it 'flips the state to started state without reseting/reloading the original object (only state record)' do
          subject.verification_failure = 'draft changes'

          expect { subject.verification_started! }.to change { subject.verification_state }.from(0).to(1)
          expect(subject.verification_failure).to eq('draft changes')
        end
      end
    end
  end

  context 'for registry classes' do
    describe '.fail_verification_timeouts' do
      it 'sets verification state to failed' do
        registry = create(:geo_package_file_registry, :synced, verification_started_at: (described_class::VERIFICATION_TIMEOUT + 1.minute).ago, verification_state: 1)

        registry.class.fail_verification_timeouts

        expect(registry.reload.verification_failed?).to be_truthy
      end
    end

    describe '.verification_not_disabled' do
      it 'returns available verifiables, excluding verification_disabled' do
        factory = :geo_package_file_registry
        pending = create(factory, :synced, verification_state: Geo::PackageFileRegistry.verification_state_value(:verification_pending))
        started = create(factory, :synced, verification_state: Geo::PackageFileRegistry.verification_state_value(:verification_started))
        succeeded = create(factory, :synced, verification_state: Geo::PackageFileRegistry.verification_state_value(:verification_succeeded), verification_checksum: 'abc123')
        failed = create(factory, :synced, verification_state: Geo::PackageFileRegistry.verification_state_value(:verification_failed), verification_failure: 'Foo bar')

        # disabled will not be returned
        create(factory, :synced, verification_state: Geo::PackageFileRegistry.verification_state_value(:verification_disabled))

        expect(pending.class.verification_not_disabled).to match_array([pending, started, succeeded, failed])
      end
    end

    describe '#verification_started!' do
      it 'flips the state to started state' do
        registry = create(:geo_package_file_registry)

        expect { registry.verification_started! }.to change { registry.verification_state }.from(0).to(1)
      end
    end
  end
end
