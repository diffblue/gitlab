# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::MigrateRecordsToGhostUserService, feature_category: :user_management do
  let!(:user) { create(:user) }
  let(:service) { described_class.new(user, admin, execution_tracker) }
  let(:execution_tracker) { instance_double(::Gitlab::Utils::ExecutionTracker, over_limit?: false) }

  let_it_be(:admin) { create(:admin) }

  context "when migrating a user's associated records to the ghost user" do
    context 'for epics' do
      context 'when deleted user is present as both author and edited_user' do
        include_examples 'migrating records to the ghost user', Epic, [:author, :last_edited_by] do
          let(:created_record) do
            create(:epic, group: create(:group), author: user, last_edited_by: user)
          end
        end
      end

      context 'when deleted user is present only as edited_user' do
        include_examples 'migrating records to the ghost user', Epic, [:last_edited_by] do
          let(:created_record) { create(:epic, group: create(:group), author: create(:user), last_edited_by: user) }
        end
      end
    end

    context 'for vulnerability_feedback author' do
      include_examples 'migrating records to the ghost user', Vulnerabilities::Feedback, [:author] do
        let(:created_record) { create(:vulnerability_feedback, author: user) }
      end
    end

    context 'for vulnerability_feedback comment author' do
      include_examples 'migrating records to the ghost user', Vulnerabilities::Feedback, [:comment_author] do
        let(:created_record) { create(:vulnerability_feedback, comment_author: user) }
      end
    end

    context 'for vulnerability author' do
      include_examples 'migrating records to the ghost user', Vulnerability, [:author] do
        let(:created_record) { create(:vulnerability, author: user) }
      end
    end

    context 'for vulnerability_external_issue_link author' do
      include_examples 'migrating records to the ghost user', Vulnerabilities::ExternalIssueLink, [:author] do
        let(:created_record) { create(:vulnerabilities_external_issue_link, author: user) }
      end
    end

    context 'for resource_iteration_events' do
      let(:always_ghost) { true }

      include_examples 'migrating records to the ghost user', ResourceIterationEvent, [:user] do
        let(:created_record) do
          create(:resource_iteration_event, issue: create(:issue),
                                            user: user,
                                            iteration: create(:iteration))
        end
      end
    end
  end

  context 'on post-migrate cleanups' do
    subject(:operation) { service.execute }

    describe 'audit events' do
      include_examples 'audit event logging' do
        let(:fail_condition!) do
          expect(user).to receive(:destroy).and_return(user)
          expect(user).to receive(:destroyed?).and_return(false)
        end

        let(:attributes) do
          {
            author_id: admin.id,
            entity_id: user.id,
            entity_type: 'User',
            details: {
              remove: 'user',
              author_name: admin.name,
              target_id: user.id,
              target_type: 'User',
              target_details: user.full_path
            }
          }
        end
      end
    end
  end
end
