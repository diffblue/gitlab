# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SyncSeatLinkWorker, type: :worker, feature_category: :sm_provisioning do
  describe '#perform' do
    context 'when current, paid license is active' do
      let(:utc_time) { Time.utc(2020, 3, 12, 12, 00) }

      before do
        # Setting the date as 12th March 2020 12:00 UTC for tests and creating new license
        create_current_license(cloud_licensing_enabled: true, starts_at: '2020-02-12'.to_date)

        create(:historical_data, recorded_at: '2020-02-11T00:00:00Z', active_user_count: 100)
        create(:historical_data, recorded_at: '2020-02-12T00:00:00Z', active_user_count: 10)
        create(:historical_data, recorded_at: '2020-02-13T00:00:00Z', active_user_count: 15)

        create(:historical_data, recorded_at: '2020-03-11T00:00:00Z', active_user_count: 10)
        create(:historical_data, recorded_at: '2020-03-12T00:00:00Z', active_user_count: 12)
        create(:historical_data, recorded_at: '2020-03-15T00:00:00Z', active_user_count: 25)
        allow(SyncSeatLinkRequestWorker).to receive(:perform_async).and_return(true)
      end

      it 'executes the SyncSeatLinkRequestWorker with expected params' do
        travel_to(utc_time) do
          subject.perform

          expect(SyncSeatLinkRequestWorker).to have_received(:perform_async)
            .with(
              '2020-03-12T00:00:00Z',
              License.current.data,
              15,
              12
            )
        end
      end

      context 'when the timezone makes date one day in advance' do
        around do |example|
          Time.use_zone('Auckland') { example.run }
        end

        it 'executes the SyncSeatLinkRequestWorker with expected params' do
          travel_to(utc_time) do
            expect(Date.current.to_s).to eql('2020-03-13')

            subject.perform

            # Time.iso8601('2020-03-12T13:00:00+13:00') == Time.iso8601('2020-03-12T00:00:00Z')
            expect(SyncSeatLinkRequestWorker).to have_received(:perform_async)
              .with(
                '2020-03-12T13:00:00+13:00',
                License.current.data,
                15,
                12
              )
          end
        end

        context 'when the timezone makes date one day before than UTC' do
          around do |example|
            Time.use_zone('Central America') { example.run }
          end

          it 'executes the SyncSeatLinkRequestWorker with expected params' do
            travel_to(utc_time.beginning_of_day) do
              expect(Date.current.to_s).to eql('2020-03-11')

              subject.perform

              # Time.iso8601('2020-03-11T18:00:00-06:00') == Time.iso8601('2020-03-12T00:00:00Z')
              expect(SyncSeatLinkRequestWorker).to have_received(:perform_async)
                .with(
                  '2020-03-11T18:00:00-06:00',
                  License.current.data,
                  15,
                  12
                )
            end
          end
        end
      end
    end

    shared_examples 'no seat link sync' do
      it 'does not execute the SyncSeatLinkRequestWorker' do
        expect(SyncSeatLinkRequestWorker).not_to receive(:perform_async)

        subject.perform
      end
    end

    shared_examples 'seat link sync' do
      it 'executes the SyncSeatLinkRequestWorker' do
        expect(SyncSeatLinkRequestWorker).to receive(:perform_async).and_return(true)

        subject.perform
      end
    end

    context 'license checks' do
      let_it_be(:historical_data) { create(:historical_data) }

      context 'when license is missing' do
        before do
          License.current.destroy!
        end

        include_examples 'no seat link sync'
      end

      context 'when using a trial license' do
        before do
          create(:license, trial: true)
        end

        include_examples 'no seat link sync'
      end

      context 'when the license has no expiration date' do
        before do
          create_current_license_without_expiration(cloud_licensing_enabled: true, block_changes_at: nil)
        end

        include_examples 'no seat link sync'
      end

      context 'when using an expired license' do
        before do
          create_current_license(cloud_licensing_enabled: true, expires_at: Time.zone.now.utc.to_date - 15.days)
        end

        include_examples 'seat link sync'
      end
    end

    context 'with a non cloud license' do
      before do
        create_current_license(starts_at: '2020-02-12'.to_date)
      end

      include_examples 'no seat link sync'
    end
  end
end
