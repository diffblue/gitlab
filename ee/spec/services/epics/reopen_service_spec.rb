# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Epics::ReopenService, feature_category: :portfolio_management do
  let_it_be(:group) { create(:group, :internal) }
  let_it_be(:user) { create(:user) }
  let_it_be(:epic, reload: true) { create(:epic, group: group, state: :closed, closed_at: Date.today, closed_by: user) }

  describe '#execute' do
    subject { described_class.new(group: group, current_user: user) }

    context 'when epics are disabled' do
      before do
        group.add_maintainer(user)
      end

      it 'does not reopen the epic' do
        expect { subject.execute(epic) }.not_to change { epic.state }
      end
    end

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when a user has permissions to update the epic' do
        before_all do
          group.add_maintainer(user)
        end

        context 'when reopening a closed epic' do
          it 'reopens the epic' do
            expect { subject.execute(epic) }.to change { epic.state }.from('closed').to('opened')
          end

          it 'removes closed_by' do
            expect { subject.execute(epic) }.to change { epic.closed_by }.to(nil)
          end

          it 'removes closed_at' do
            expect { subject.execute(epic) }.to change { epic.closed_at }.to(nil)
          end

          it 'creates a resource state event' do
            expect { subject.execute(epic) }.to change { epic.resource_state_events.count }.by(1)

            event = epic.resource_state_events.last

            expect(event.state).to eq('opened')
          end

          it 'notifies the subscribers' do
            notification_service = double

            expect(NotificationService).to receive(:new).and_return(notification_service)
            expect(notification_service).to receive(:reopen_epic).with(epic, user)

            subject.execute(epic)
          end

          it 'creates new event' do
            expect { subject.execute(epic) }.to change { Event.count }
          end

          it 'tracks reopening the epic' do
            expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
              .to receive(:track_epic_reopened_action).with(author: user, namespace: group)

            subject.execute(epic)
          end
        end

        context 'when trying to reopen an opened epic' do
          before do
            epic.update!(state: :opened)
          end

          it 'does not change the epic state' do
            expect { subject.execute(epic) }.not_to change { epic.state }
          end

          it 'does not change closed_at' do
            expect { subject.execute(epic) }.not_to change { epic.closed_at }
          end

          it 'does not change closed_by' do
            expect { subject.execute(epic) }.not_to change { epic.closed_by }
          end

          it 'does not create a resource state event' do
            expect { subject.execute(epic) }.not_to change { epic.resource_state_events.count }
          end

          it 'does not send any emails' do
            expect(NotificationService).not_to receive(:new)

            subject.execute(epic)
          end

          it 'does not create an event' do
            expect { subject.execute(epic) }.not_to change { Event.count }
          end

          it 'does not track reopening the epic' do
            expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).not_to receive(:track_epic_reopened_action)

            subject.execute(epic)
          end
        end
      end

      context 'when a user does not have permissions to update epic' do
        it 'does not reopen the epic' do
          expect { subject.execute(epic) }.not_to change { epic.state }
        end
      end
    end
  end
end
