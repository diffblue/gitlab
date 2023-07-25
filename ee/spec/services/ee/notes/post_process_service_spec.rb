# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::PostProcessService, feature_category: :team_planning do
  describe '#execute' do
    context 'analytics' do
      subject { described_class.new(note) }

      let(:note) { create(:note) }
      let(:analytics_mock) { instance_double('Analytics::RefreshCommentsData') }

      it 'invokes Analytics::RefreshCommentsData' do
        allow(Analytics::RefreshCommentsData).to receive(:for_note).with(note).and_return(analytics_mock)

        expect(analytics_mock).to receive(:execute)

        subject.execute
      end
    end

    context 'for audit events' do
      subject(:notes_post_process_service) { described_class.new(note) }

      context 'when note author is a project bot' do
        let_it_be(:project_bot) { create(:user, :project_bot, email: "bot@example.com") }

        let(:note) { create(:note, author: project_bot) }

        it 'audits with correct name' do
          # Stub .audit here so that only relevant audit events are received below
          allow(::Gitlab::Audit::Auditor).to receive(:audit)

          expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
            hash_including(name: "comment_by_project_bot", stream_only: true)
          ).and_call_original

          notes_post_process_service.execute
        end

        it 'does not persist the audit event to database' do
          expect { notes_post_process_service.execute }.not_to change { AuditEvent.count }
        end
      end

      context 'when note author is not a project bot' do
        let(:note) { create(:note) }

        it 'does not invoke Gitlab::Audit::Auditor' do
          expect(::Gitlab::Audit::Auditor).not_to receive(:audit).with(hash_including(
            name: 'comment_by_project_bot'
          ))

          notes_post_process_service.execute
        end

        it 'does not create an audit event' do
          expect { notes_post_process_service.execute }.not_to change { AuditEvent.count }
        end
      end
    end
  end
end
