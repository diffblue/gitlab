# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Notify do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  include EmailHelpers
  include RepoHelpers

  include_context 'gitlab email notification'

  RSpec.shared_examples 'epic notifications with reply' do
    it_behaves_like 'having group identification headers'

    it_behaves_like 'it should show Gmail Actions View Epic link'

    it_behaves_like 'an unsubscribeable thread'

    it 'has the characteristics of a threaded reply' do
      host = Gitlab.config.gitlab.host
      route_key = "#{epic.class.model_name.singular_route_key}_#{epic.id}"

      aggregate_failures do
        is_expected.to have_header('Message-ID', /\A<.*@#{host}>\Z/)
        is_expected.to have_header('In-Reply-To', "<#{route_key}@#{host}>")
        is_expected.to have_header('References',  /\A<reply\-.*@#{host}> <#{route_key}@#{host}>\Z/ )
        is_expected.to have_subject(/^Re: /)
      end
    end

    it 'has a Reply-To header' do
      is_expected.to have_header 'Reply-To', /<reply+(.*)@#{Gitlab.config.gitlab.host}>\Z/
    end

    it 'has the correct subject and body' do
      email_subject = "Re: #{epic.group.name} | #{epic.title} (#{epic.to_reference})"

      aggregate_failures do
        is_expected.to have_subject(email_subject)
        is_expected.to have_body_text(email_body)
      end
    end
  end

  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:current_user) { create(:user, email: "current@email.com") }
  let_it_be(:assignee) { create(:user, email: 'assignee@example.com', name: 'John Doe') }
  let_it_be(:assignee2) { create(:user, email: 'assignee2@example.com', name: 'Jane Doe') }

  let_it_be(:merge_request, reload: true) do
    create(
      :merge_request,
      source_project: project,
      target_project: project,
      author: current_user,
      assignees: [assignee, assignee2],
      description: 'Awesome description'
    )
  end

  let_it_be(:issue, reload: true) do
    create(
      :issue,
      author: current_user,
      assignees: [assignee],
      project: project,
      description: 'My awesome description!'
    )
  end

  let_it_be(:project2, reload: true) { create(:project, :repository) }
  let_it_be(:merge_request_without_assignee, reload: true) do
    create(
      :merge_request,
      source_project: project2,
      author: current_user,
      description: 'Awesome description'
    )
  end

  context 'for a project' do
    context 'for merge requests' do
      describe "that are new with approver" do
        before do
          create(:approver, target: merge_request)
        end

        subject do
          described_class.new_merge_request_email(assignee.id, merge_request.id)
        end

        it "contains the approvers list" do
          is_expected.to have_body_text %r[#{merge_request.approvers.first.user.name}]
        end
      end

      describe 'that are approved' do
        let(:last_approver) { create(:user) }

        subject { described_class.approved_merge_request_email(recipient.id, merge_request.id, last_approver.id) }

        before do
          merge_request.approvals.create!(user: assignee)
          merge_request.approvals.create!(user: last_approver)
        end

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end

        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'

        it 'is sent as the last approver' do
          expect_sender(last_approver)
        end

        it 'has the correct subject' do
          is_expected.to have_attributes(
            subject: a_string_including("#{merge_request.title} (#{merge_request.to_reference})")
          )
        end

        it 'contains the new status' do
          is_expected.to have_body_text('approved')
        end

        it 'contains a link to the merge request' do
          is_expected.to have_body_text(project_merge_request_path(project, merge_request))
        end

        it 'contains the names of all of the approvers' do
          names = merge_request.approvals.map { |a| a.user.name }

          aggregate_failures do
            names.each { |name| is_expected.to have_body_text(name) }
          end
        end

        it 'contains the names of all assignees' do
          names = merge_request.assignees.map(&:name)

          aggregate_failures do
            names.each { |name| is_expected.to have_body_text(name) }
          end
        end

        context 'when merge request has no assignee' do
          before do
            merge_request.update!(assignees: [])
          end

          it 'does not show the assignee' do
            is_expected.not_to have_body_text 'Assignee'
          end
        end
      end

      describe 'that are unapproved' do
        let(:last_unapprover) { create(:user) }

        subject { described_class.unapproved_merge_request_email(recipient.id, merge_request.id, last_unapprover.id) }

        before do
          merge_request.approvals.create!(user: assignee)
        end

        it_behaves_like 'a multiple recipients email'
        it_behaves_like 'an answer to an existing thread with reply-by-email enabled' do
          let(:model) { merge_request }
        end

        it_behaves_like 'it should show Gmail Actions View Merge request link'
        it_behaves_like 'an unsubscribeable thread'

        it 'is sent as the last unapprover' do
          expect_sender(last_unapprover)
        end

        it 'has the correct subject' do
          is_expected.to have_attributes(
            subject: a_string_including("#{merge_request.title} (#{merge_request.to_reference})")
          )
        end

        it 'contains the new status' do
          is_expected.to have_body_text('unapproved')
        end

        it 'contains a link to the merge request' do
          is_expected.to have_body_text(project_merge_request_path(project, merge_request))
        end

        it 'contains the names of all of the approvers' do
          names = merge_request.approvals.map { |a| a.user.name }

          aggregate_failures do
            names.each { |name| is_expected.to have_body_text(name) }
          end
        end

        it 'contains the names of all assignees' do
          names = merge_request.assignees.map(&:name)

          aggregate_failures do
            names.each { |name| is_expected.to have_body_text(name) }
          end
        end
      end
    end

    context 'for merge requests without assignee' do
      describe 'that are unapproved' do
        let(:last_unapprover) { create(:user) }

        subject { described_class.unapproved_merge_request_email(recipient.id, merge_request_without_assignee.id, last_unapprover.id) }

        it 'contains the new status' do
          is_expected.to have_body_text('unapproved')
        end
      end
    end
  end

  context 'for a group' do
    describe 'for epics' do
      let_it_be(:group) { create(:group) }
      let_it_be(:epic) { create(:epic, group: group) }

      context 'that are new' do
        subject { described_class.new_epic_email(recipient.id, epic.id) }

        it_behaves_like 'an epic email starting a new thread with reply-by-email enabled' do
          let(:model) { epic }
        end

        it_behaves_like 'it should show Gmail Actions View Epic link'
        it_behaves_like 'an unsubscribeable thread'
        it_behaves_like 'having group identification headers'

        it 'has the correct subject and body' do
          prefix = "#{epic.group.name} | "
          suffix = "#{epic.title} (#{epic.to_reference})"

          aggregate_failures do
            is_expected.to have_subject [prefix, suffix].compact.join
            is_expected.to have_body_text(group_epic_path(group, epic))
          end
        end

        it 'contains a link to epic author' do
          is_expected.to have_body_text(epic.author_name)
          is_expected.to have_body_text 'created an epic:'
          is_expected.to have_link(epic.to_reference, href: group_epic_url(group, epic))
        end

        it 'contains a link to the epic' do
          is_expected.to have_body_text(epic.to_reference)
        end

        context 'got deleted before notification' do
          subject { described_class.new_epic_email(recipient.id, 0) }

          it 'does not send email' do
            expect(subject.message).to be_a_kind_of ActionMailer::Base::NullMail
          end
        end
      end

      context 'that changed status' do
        let(:status) { 'reopened' }

        subject { described_class.epic_status_changed_email(recipient.id, epic.id, status, current_user.id) }

        it_behaves_like 'epic notifications with reply' do
          let(:email_body) { "Epic was #{status} by #{current_user.name}" }
        end
      end

      context 'for epic notes' do
        let_it_be(:note) { create(:note, project: nil, noteable: epic) }

        let(:note_author) { note.author }

        subject { described_class.note_epic_email(recipient.id, note.id) }

        it_behaves_like 'epic notifications with reply' do
          let(:email_body) { group_epic_path(group, epic, anchor: "note_#{note.id}") }
        end

        it_behaves_like 'a note email'
      end
    end
  end

  describe 'mirror was hard failed' do
    let(:project) { create(:project, :mirror, :import_hard_failed) }

    subject { described_class.mirror_was_hard_failed_email(project.id, user.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like "a user cannot unsubscribe through footer link"

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Repository mirroring paused")
      is_expected.to have_body_text(project.full_path)
      is_expected.to have_body_text(project_settings_repository_url(project))
    end
  end

  describe 'mirror was disabled' do
    let(:project) { create(:project) }

    subject { described_class.mirror_was_disabled_email(project.id, user.id, 'deleted_user_name') }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like "a user cannot unsubscribe through footer link"

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Repository mirroring disabled")
      is_expected.to have_body_text(project.full_path)
      is_expected.to have_body_text(project_settings_repository_url(project))
      is_expected.to have_body_text('deleted_user_name')
    end

    context 'user was deleted' do
      before do
        user.destroy!
      end

      it 'does not send email' do
        expect(subject.message).to be_a_kind_of ActionMailer::Base::NullMail
      end
    end
  end

  describe 'mirror user changed' do
    let(:mirror_user) { create(:user) }
    let(:project) { create(:project, :mirror, mirror_user_id: mirror_user.id) }
    let(:new_mirror_user) { project.team.owners.first }

    subject { described_class.project_mirror_user_changed_email(new_mirror_user.id, mirror_user.name, project.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like "a user cannot unsubscribe through footer link"

    it 'has the correct subject and body' do
      is_expected.to have_subject("#{project.name} | Mirror user changed")
      is_expected.to have_body_text(project.full_path)
    end
  end

  describe 'new user was created via saml' do
    let(:group_member) { create(:group_member, user: create(:user, :unconfirmed)) }
    let(:group) { group_member.source }
    let(:recipient) { group_member.user }

    subject { described_class.provisioned_member_access_granted_email(group_member.id) }

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'delivers mail to user email' do
      expect(subject).to deliver_to(recipient.email)
    end

    it 'contains all the useful information' do
      is_expected.to have_subject 'Welcome to GitLab'
      is_expected.to have_body_text group.name
      is_expected.to have_body_text group.web_url
      is_expected.to have_body_text recipient.username
      is_expected.to have_body_text recipient.email
      is_expected.to have_body_text 'To get started, click the link below to confirm your account'
      is_expected.to have_body_text recipient.confirmation_token
    end
  end

  def expect_sender(user)
    sender = subject.header[:from].addrs[0]
    expect(sender.display_name).to eq("#{user.name} (@#{user.username})")
    expect(sender.address).to eq(gitlab_sender)
  end
end
