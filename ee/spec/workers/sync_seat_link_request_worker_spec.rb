# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SyncSeatLinkRequestWorker, type: :worker, feature_category: :sm_provisioning do
  describe '#perform' do
    subject(:sync_seat_link) do
      described_class.new.perform('2020-01-01T01:20:12+02:00', '123', 5, 4)
    end

    let(:subscription_portal_url) { ::Gitlab::Routing.url_helpers.subscription_portal_url }
    let(:seat_link_url) { [subscription_portal_url, '/api/v1/seat_links'].join }

    it 'makes an HTTP POST request with passed params' do
      stub_request(:post, seat_link_url).to_return(status: 200)
      allow(Gitlab::CurrentSettings).to receive(:uuid).and_return('one-two-three')

      sync_seat_link

      expect(WebMock).to have_requested(:post, seat_link_url).with(
        headers: { 'Content-Type' => 'application/json' },
        body: {
          gitlab_version: Gitlab::VERSION,
          timestamp: '2019-12-31T23:20:12Z',
          license_key: '123',
          max_historical_user_count: 5,
          billable_users_count: 4,
          hostname: Gitlab.config.gitlab.host,
          instance_id: 'one-two-three'
        }.to_json
      )
    end

    context 'when response contains a license' do
      let(:license_key) { build(:gitlab_license, :cloud).export }
      let(:body) { { success: true, license: license_key }.to_json }

      before do
        stub_request(:post, seat_link_url).to_return(
          status: 200,
          body: body,
          headers: { content_type: 'application/json' }
        )
      end

      shared_examples 'successful license creation' do
        it 'persists the new license' do
          freeze_time do
            expect { sync_seat_link }.to change(License, :count).by(1)
            expect(License.current).to have_attributes(
              data: license_key,
              cloud: true,
              last_synced_at: Time.current
            )
          end
        end
      end

      context 'when there is no previous license' do
        before do
          License.delete_all
        end

        it_behaves_like 'successful license creation'
      end

      context 'when there is a previous license' do
        context 'when it is a cloud license' do
          context 'when the current license key does not match the one returned from sync' do
            it 'creates a new license' do
              freeze_time do
                current_license = create(:license, cloud: true, last_synced_at: 1.day.ago)

                expect { sync_seat_link }.to change(License.cloud, :count).by(1)

                new_current_license = License.current
                expect(new_current_license).not_to eq(current_license.id)
                expect(new_current_license).to have_attributes(
                  data: license_key,
                  cloud: true,
                  last_synced_at: Time.current
                )
              end
            end
          end

          context 'when the current license key matches the one returned from sync' do
            it 'reuses the current license and updates the last_synced_at', :request_store do
              freeze_time do
                current_license = create(:license, cloud: true, data: license_key, last_synced_at: 1.day.ago)

                expect { sync_seat_link }.not_to change(License.cloud, :count)

                expect(License.current).to have_attributes(
                  id: current_license.id,
                  data: license_key,
                  cloud: true,
                  last_synced_at: Time.current
                )
              end
            end
          end

          context 'when persisting fails' do
            let(:license_key) { 'invalid-key' }

            it 'does not delete the current license and logs error' do
              current_license = License.current
              expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original

              expect { sync_seat_link }.to raise_error ActiveRecord::RecordInvalid

              expect(License).to exist(current_license.id)
            end
          end
        end

        context 'when it is not a cloud license' do
          before do
            create(:license)
          end

          it_behaves_like 'successful license creation'
        end
      end
    end

    context 'when response contains reconciliation dates' do
      let(:body) { { success: true, next_reconciliation_date: today.to_s, display_alert_from: (today - 7.days).to_s }.to_json }
      let(:today) { Date.current }

      before do
        stub_request(:post, seat_link_url).to_return(
          status: 200,
          body: body,
          headers: { content_type: 'application/json' }
        )
      end

      it 'saves the reconciliation dates' do
        sync_seat_link
        upcoming_reconciliation = GitlabSubscriptions::UpcomingReconciliation.next

        expect(upcoming_reconciliation.next_reconciliation_date).to eq(today)
        expect(upcoming_reconciliation.display_alert_from).to eq(today - 7.days)
      end

      context 'when an upcoming_reconciliation already exists' do
        it 'updates the upcoming_reconciliation' do
          upcoming_reconciliation = create(:upcoming_reconciliation, :self_managed, next_reconciliation_date: today + 2.days, display_alert_from: today + 1.day)

          sync_seat_link

          upcoming_reconciliation.reload

          expect(upcoming_reconciliation.next_reconciliation_date).to eq(today)
          expect(upcoming_reconciliation.display_alert_from).to eq(today - 7.days)
        end
      end
    end

    context 'when response contains future subscription information' do
      let(:future_subscriptions) { [{ 'foo' => 'bar' }] }
      let(:body) { { success: true, future_subscriptions: future_subscriptions }.to_json }
      let(:today) { Date.current }

      before do
        stub_request(:post, seat_link_url).to_return(
          status: 200,
          body: body,
          headers: { content_type: 'application/json' }
        )
      end

      context 'when future subscription information is present in the response' do
        context 'and no future subscriptions are saved in the current settings' do
          it 'persists future subscription information' do
            expect { sync_seat_link }.to change { Gitlab::CurrentSettings.current_application_settings.future_subscriptions }.from([]).to(future_subscriptions)
          end
        end

        context 'and future subscriptions are saved in the current settings' do
          before do
            Gitlab::CurrentSettings.current_application_settings.update!(future_subscriptions: [{}])
          end

          it 'replaces future subscription information' do
            expect { sync_seat_link }.to change { Gitlab::CurrentSettings.current_application_settings.future_subscriptions }.from([{}]).to(future_subscriptions)
          end
        end
      end

      context 'when future subscription information is not present in the response' do
        let(:future_subscriptions) { [] }

        context 'and no future subscriptions are saved in the current settings' do
          it 'does not change the settings' do
            expect { sync_seat_link }.not_to change { Gitlab::CurrentSettings.current_application_settings.future_subscriptions }.from(future_subscriptions)
          end
        end

        context 'and future subscription are saved in the current settings' do
          before do
            Gitlab::CurrentSettings.current_application_settings.update!(future_subscriptions: [{}])
          end

          it 'clears future subscription information' do
            expect { sync_seat_link }.to change { Gitlab::CurrentSettings.current_application_settings.future_subscriptions }.from([{}]).to(future_subscriptions)
          end
        end
      end

      context 'when saving fails' do
        it 'logs error' do
          allow(Gitlab::CurrentSettings.current_application_settings).to receive(:save!).and_raise('saving fails')

          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
          expect { sync_seat_link }.not_to raise_error
        end
      end
    end

    context 'when the response does not contain reconciliation dates' do
      let(:body) do
        {
          success: true,
          next_reconciliation_date: nil,
          display_alert_from: nil
        }.to_json
      end

      before do
        stub_request(:post, seat_link_url).to_return(
          status: 200,
          body: body,
          headers: { content_type: 'application/json' }
        )
      end

      it 'destroys the existing upcoming reconciliation record for the instance' do
        create(:upcoming_reconciliation, :self_managed)

        expect { sync_seat_link }
          .to change(GitlabSubscriptions::UpcomingReconciliation, :count)
          .by(-1)
      end

      it 'does not change anything when there is no existing record' do
        expect { sync_seat_link }.not_to change(GitlabSubscriptions::UpcomingReconciliation, :count)
      end
    end

    shared_examples 'unsuccessful request' do
      context 'when the request is not successful' do
        before do
          stub_request(:post, seat_link_url)
            .to_return(status: 400, body: '{"success":false,"error":"Bad Request"}')
        end

        it 'raises an error with the expected message' do
          expect { sync_seat_link }.to raise_error(
            described_class::RequestError,
            'Seat Link request failed! Code:400 Body:{"success":false,"error":"Bad Request"}'
          )
        end
      end
    end

    it_behaves_like 'unsuccessful request'
  end

  describe 'sidekiq_retry_in_block' do
    it 'is at least 30 minutes in the first retry' do
      expect(
        described_class.sidekiq_retry_in_block.call(0, nil)
      ).to be >= 30.minutes
    end
  end
end
