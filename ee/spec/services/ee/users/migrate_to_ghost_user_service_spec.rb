# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::MigrateToGhostUserService do
  let!(:user)   { create(:user) }
  let(:service) { described_class.new(user) }
  let(:always_ghost) { false }

  context 'epics' do
    context 'deleted user is present as both author and edited_user' do
      include_examples "migrating a deleted user's associated records to the ghost user", Epic, [:author, :last_edited_by] do
        let(:created_record) do
          create(:epic, group: create(:group), author: user, last_edited_by: user)
        end
      end
    end

    context 'deleted user is present only as edited_user' do
      include_examples "migrating a deleted user's associated records to the ghost user", Epic, [:last_edited_by] do
        let(:created_record) { create(:epic, group: create(:group), author: create(:user), last_edited_by: user) }
      end
    end
  end

  context 'vulnerability_feedback author' do
    include_examples "migrating a deleted user's associated records to the ghost user", Vulnerabilities::Feedback, [:author] do
      let(:created_record) { create(:vulnerability_feedback, author: user) }
    end
  end

  context 'vulnerability_feedback comment author' do
    include_examples "migrating a deleted user's associated records to the ghost user", Vulnerabilities::Feedback, [:comment_author] do
      let(:created_record) { create(:vulnerability_feedback, comment_author: user) }
    end
  end

  context 'vulnerability author' do
    include_examples "migrating a deleted user's associated records to the ghost user", Vulnerability, [:author] do
      let(:created_record) { create(:vulnerability, author: user) }
    end
  end

  context 'vulnerability_external_issue_link author' do
    include_examples "migrating a deleted user's associated records to the ghost user", Vulnerabilities::ExternalIssueLink, [:author] do
      let(:created_record) { create(:vulnerabilities_external_issue_link, author: user) }
    end
  end

  context 'vulnerability_state_transitions author' do
    include_examples "migrating a deleted user's associated records to the ghost user", Vulnerabilities::StateTransition, [:author] do
      let(:created_record) { create(:vulnerability_state_transitions, author: user) }
    end
  end

  context 'resource_iteration_events' do
    let(:always_ghost) { true }

    include_examples "migrating a deleted user's associated records to the ghost user", ResourceIterationEvent, [:user] do
      let(:created_record) { create(:resource_iteration_event, issue: create(:issue), user: user, iteration: create(:iteration)) }
    end
  end
end
