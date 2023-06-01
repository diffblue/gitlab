# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NewEpicWorker, feature_category: :portfolio_management do
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'when an epic not found' do
      it 'does not call Services' do
        expect(NotificationService).not_to receive(:new)

        worker.perform(non_existing_record_id, create(:user).id)
      end

      it 'logs an error' do
        expect(Gitlab::AppLogger).to receive(:error).with("NewEpicWorker: couldn't find Epic with ID=#{non_existing_record_id}, skipping job")

        worker.perform(non_existing_record_id, create(:user).id)
      end
    end

    context 'when a user not found' do
      it 'does not call Services' do
        expect(NotificationService).not_to receive(:new)

        worker.perform(create(:epic).id, non_existing_record_id)
      end

      it 'logs an error' do
        expect(Gitlab::AppLogger).to receive(:error).with("NewEpicWorker: couldn't find User with ID=#{non_existing_record_id}, skipping job")

        worker.perform(create(:epic).id, non_existing_record_id)
      end
    end

    context 'with a user' do
      let(:epic) { create(:epic) }

      before do
        stub_licensed_features(epics: true)
      end

      shared_examples 'a new epic where the current user cannot trigger notifications' do
        it 'does not create a notification for the mentioned user' do
          expect(Notify).not_to receive(:new_epic_email).with(user.id, epic.id, nil)

          expect(Gitlab::AppLogger).to receive(:warn).with(message: 'Skipping sending notifications', user: user.id, klass: epic.class.to_s, object_id: epic.id)

          worker.perform(epic.id, user.id)
        end
      end

      context 'when the new epic author is not confirmed' do
        let_it_be(:user) { create(:user, :unconfirmed) }

        it_behaves_like 'a new epic where the current user cannot trigger notifications'
      end

      context 'when the new epic author is blocked' do
        let_it_be(:user) { create(:user, :blocked) }

        it_behaves_like 'a new epic where the current user cannot trigger notifications'
      end

      context 'when the new epic author is a ghost' do
        let_it_be(:user) { create(:user, :ghost) }

        it_behaves_like 'a new epic where the current user cannot trigger notifications'
      end

      context 'when everything is ok' do
        let(:user) { create(:user) }

        it 'creates an event' do
          expect { worker.perform(epic.id, user.id) }.to change { Event.count }.from(0).to(1)
        end

        context 'user watches group' do
          before do
            create(
              :notification_setting,
              user: user,
              source: epic.group,
              level: NotificationSetting.levels[:watch]
            )
          end

          it 'creates a notification for watcher' do
            expect(Notify).to receive(:new_epic_email).with(user.id, epic.id, nil)
              .and_return(double(deliver_later: true))

            worker.perform(epic.id, user.id)
          end
        end

        context 'mention' do
          let(:epic) { create(:epic, description: "epic for #{user.to_reference}") }

          it 'creates a notification for the mentioned user' do
            expect(Notify).to receive(:new_epic_email).with(user.id, epic.id, NotificationReason::MENTIONED)
              .and_return(double(deliver_later: true))

            worker.perform(epic.id, user.id)
          end
        end

        context 'when project bot it logs audit events' do
          let_it_be(:project_bot) { create(:user, :project_bot, email: "bot@example.com") }

          include_examples 'audit event logging' do
            let(:epic) { create(:epic, author: project_bot) }
            let(:operation) { worker.perform(epic.id, project_bot.id) }
            let(:event_type) { 'epic_created_by_project_bot' }
            let(:fail_condition!) { allow_any_instance_of(User).to receive(:project_bot?).and_return(false) } # rubocop:disable RSpec/AnyInstanceOf
            let(:attributes) do
              {
                author_id: project_bot.id,
                entity_id: epic.group.id,
                entity_type: 'Group',
                details: {
                  author_name: project_bot.name,
                  target_id: epic.id,
                  target_type: 'Epic',
                  target_details: {
                    iid: epic.iid,
                    id: epic.id
                  }.to_s,
                  author_class: project_bot.class.name,
                  custom_message: "Created epic #{epic.title}"
                }
              }
            end
          end
        end
      end
    end
  end
end
