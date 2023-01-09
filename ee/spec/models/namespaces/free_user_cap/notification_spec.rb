# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::Notification, :saas, feature_category: :experimentation_conversion do
  let_it_be(:namespace, reload: true) { create(:group_with_plan, :private, plan: :free_plan) }
  let(:free_user_count) { 1 }
  let(:enforcement_limit) { 3 }

  before do
    stub_ee_application_setting(dashboard_limit_enabled: true)
    allow(::Namespaces::FreeUserCap::UsersFinder).to receive(:count).and_return({ user_ids: free_user_count })
    stub_ee_application_setting(dashboard_enforcement_limit: enforcement_limit)
  end

  describe '#over_limit?' do
    subject(:over_limit?) { described_class.new(namespace).over_limit? }

    context 'when :preview_free_user_cap is disabled' do
      before do
        stub_feature_flags(preview_free_user_cap: false)
      end

      it { is_expected.to be false }
    end

    context 'when :preview_free_user_cap is enabled' do
      it { is_expected.to be true }

      it 'logs a message with counts' do
        expect(Gitlab::AppLogger)
          .to receive(:info)
                .with(a_hash_including(message: 'Namespace qualifies for counting users',
                                       class: described_class.name,
                                       namespace_id: namespace.id,
                                       user_ids: free_user_count))
                .and_call_original

        over_limit?
      end

      context 'with updating dashboard_notification_at field', :use_clean_rails_redis_caching do
        context 'when cache has expired or does not exist' do
          context 'when under the limit' do
            let(:free_user_count) { 1 }

            before do
              stub_ee_application_setting(dashboard_notification_limit: enforcement_limit - 1)
            end

            it 'updates the database for non notification' do
              time = Time.current
              namespace.namespace_details.update!(dashboard_notification_at: time)

              expect do
                expect(over_limit?).to be(false)
              end.to change { namespace.namespace_details.dashboard_notification_at }.from(time).to(nil)
            end

            context 'when over the enforcement limit' do
              let(:free_user_count) { enforcement_limit + 1 }

              it 'does not change the dashboard_notification_at' do
                time = Time.current
                namespace.namespace_details.update!(dashboard_notification_at: time)

                expect(namespace.namespace_details).not_to receive(:update)

                expect do
                  expect(over_limit?).to be(false)
                end.not_to change { namespace.namespace_details.dashboard_notification_at }
              end
            end
          end

          context 'when over the limit' do
            it 'updates the database for notification' do
              namespace.namespace_details.update!(dashboard_notification_at: nil)

              freeze_time do
                expect do
                  expect(over_limit?).to be(true)
                end.to change { namespace.namespace_details.dashboard_notification_at }.from(nil).to(Time.current)
              end
            end

            context 'when the field is already set' do
              it 'does not update any of the fields' do
                namespace.namespace_details.update!(dashboard_notification_at: Time.current)

                expect(namespace.namespace_details).not_to receive(:update)

                expect do
                  expect(over_limit?).to be(true)
                end.to not_change(namespace.namespace_details, :dashboard_notification_at)
                         .and(not_change(namespace.namespace_details, :dashboard_enforcement_at))
              end
            end
          end
        end

        context 'when cache exists' do
          before do
            over_limit?
          end

          it 'does not update the database' do
            namespace.namespace_details.update!(dashboard_notification_at: nil)

            expect do
              expect(over_limit?).to be(true)
            end.not_to change { namespace.namespace_details.dashboard_notification_at }
          end
        end
      end

      context 'when the namespace is public' do
        before do
          namespace.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        end

        it { is_expected.to be false }
      end

      context 'when the namespace is over storage limit' do
        before do
          allow_next_instance_of(::Namespaces::FreeUserCap::RootSize, namespace) do |instance|
            allow(instance).to receive(:above_size_limit?).and_return(true)
          end
        end

        it { is_expected.to be false }
      end

      context 'with a net new namespace' do
        let(:enforcement_date) { Date.today }
        let_it_be(:namespace) do
          travel_to(Date.today + 2.days) do
            create(:group_with_plan, :private, plan: :free_plan)
          end
        end

        before do
          stub_ee_application_setting(dashboard_limit_new_namespace_creation_enforcement_date: enforcement_date)
          stub_ee_application_setting(dashboard_notification_limit: enforcement_limit - 2)
          stub_ee_application_setting(dashboard_limit: enforcement_limit)
        end

        context 'when under the dashboard_limit preview is honored' do
          let(:free_user_count) { enforcement_limit - 1 }

          it { is_expected.to be true }
        end

        context 'when at dashboard_limit preview is honored' do
          let(:free_user_count) { enforcement_limit }

          it { is_expected.to be true }
        end

        context 'when over the dashboard_limit preview is off' do
          let(:free_user_count) { enforcement_limit + 1 }

          it { is_expected.to be false }
        end
      end

      context 'with an existing namespace' do
        before do
          stub_ee_application_setting(dashboard_notification_limit: enforcement_limit - 2)
        end

        context 'when under the dashboard_enforcement_limit preview is honored' do
          let(:free_user_count) { enforcement_limit - 1 }

          it { is_expected.to be true }
        end

        context 'when at dashboard_enforcement_limit preview is honored' do
          let(:free_user_count) { enforcement_limit }

          it { is_expected.to be true }
        end

        context 'when over the dashboard_enforcement_limit preview is off' do
          let(:free_user_count) { enforcement_limit + 1 }

          it { is_expected.to be false }
        end
      end
    end
  end
end
