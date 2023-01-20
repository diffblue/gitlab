# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::NotificationService, :mailer, feature_category: :team_planning do
  include EmailSpec::Matchers
  include NotificationHelpers

  let(:subject) { NotificationService.new }

  let(:mailer) { double(deliver_later: true) }

  describe '.permitted_actions' do
    it 'includes public methods' do
      expect(NotificationService.permitted_actions).to include(:add_merge_request_approvers)
    end

    it 'excludes protected and private methods' do
      expect(NotificationService.permitted_actions).not_to include(:oncall_user_removed_recipients)
    end
  end

  context 'new review' do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:reviewer) { create(:user) }
    let(:merge_request) { create(:merge_request, source_project: project, assignees: [user, user2], author: create(:user)) }
    let(:review) { create(:review, merge_request: merge_request, project: project, author: reviewer) }
    let(:note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, author: reviewer, review: review) }

    before do
      build_team(review.project, merge_request)
      project.add_maintainer(merge_request.author)
      project.add_maintainer(reviewer)
      merge_request.assignees.each { |assignee| project.add_maintainer(assignee) }

      create(:diff_note_on_merge_request,
             project: project,
             noteable: merge_request,
             author: reviewer,
             review: review,
             note: "cc @mention")
    end

    it 'sends emails' do
      expect(Notify).not_to receive(:new_review_email).with(review.author.id, review.id)
      expect(Notify).not_to receive(:new_review_email).with(@unsubscriber.id, review.id)
      merge_request.assignee_ids.each do |assignee_id|
        expect(Notify).to receive(:new_review_email).with(assignee_id, review.id).and_call_original
      end
      expect(Notify).to receive(:new_review_email).with(merge_request.author.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@u_watcher.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@u_mentioned.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@subscriber.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@watcher_and_subscriber.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@subscribed_participant.id, review.id).and_call_original

      subject.new_review(review)
    end

    it_behaves_like 'project emails are disabled' do
      let(:notification_target)  { review }
      let(:notification_trigger) { subject.new_review(review) }

      around do |example|
        perform_enqueued_jobs { example.run }
      end
    end

    def build_team(project, merge_request)
      @u_watcher               = create_global_setting_for(create(:user), :watch)
      @u_participating         = create_global_setting_for(create(:user), :participating)
      @u_participant_mentioned = create_global_setting_for(create(:user, username: 'participant'), :participating)
      @u_disabled              = create_global_setting_for(create(:user), :disabled)
      @u_mentioned             = create_global_setting_for(create(:user, username: 'mention'), :mention)
      @u_committer             = create(:user, username: 'committer')
      @u_not_mentioned         = create_global_setting_for(create(:user, username: 'regular'), :participating)
      @u_outsider_mentioned    = create(:user, username: 'outsider')
      @u_custom_global         = create_global_setting_for(create(:user, username: 'custom_global'), :custom)

      # subscribers
      @subscriber = create :user
      @unsubscriber = create :user
      @unsubscribed_mentioned = create(:user, username: 'unsubscribed_mentioned')
      @subscribed_participant = create_global_setting_for(create(:user, username: 'subscribed_participant'), :participating)
      @watcher_and_subscriber = create_global_setting_for(create(:user), :watch)

      # User to be participant by default
      # This user does not contain any record in notification settings table
      # It should be treated with a :participating notification_level
      @u_lazy_participant = create(:user, username: 'lazy-participant')

      @u_guest_watcher = create_user_with_notification(:watch, 'guest_watching')
      @u_guest_custom = create_user_with_notification(:custom, 'guest_custom')

      project.add_maintainer(@u_watcher)
      project.add_maintainer(@u_participating)
      project.add_maintainer(@u_participant_mentioned)
      project.add_maintainer(@u_disabled)
      project.add_maintainer(@u_mentioned)
      project.add_maintainer(@u_committer)
      project.add_maintainer(@u_not_mentioned)
      project.add_maintainer(@u_lazy_participant)
      project.add_maintainer(@u_custom_global)
      project.add_maintainer(@subscriber)
      project.add_maintainer(@unsubscriber)
      project.add_maintainer(@subscribed_participant)
      project.add_maintainer(@watcher_and_subscriber)

      merge_request.subscriptions.create!(user: @unsubscribed_mentioned, subscribed: false)
      merge_request.subscriptions.create!(user: @subscriber, subscribed: true)
      merge_request.subscriptions.create!(user: @subscribed_participant, subscribed: true)
      merge_request.subscriptions.create!(user: @unsubscriber, subscribed: false)
      # Make the watcher a subscriber to detect dupes
      merge_request.subscriptions.create!(user: @watcher_and_subscriber, subscribed: true)
    end
  end

  describe 'mirror hard failed' do
    let(:user) { create(:user) }

    context 'when the project has invited members' do
      let(:project) { create(:project, :mirror, :import_hard_failed) }
      let!(:project_member) { create(:project_member, :invited, project: project) }

      it 'sends email' do
        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.first_owner.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { subject.mirror_was_hard_failed(project) }

        around do |example|
          perform_enqueued_jobs { example.run }
        end
      end
    end

    context 'when user is owner' do
      let(:project) { create(:project, :mirror, :import_hard_failed) }

      it 'sends email' do
        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.first_owner.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { subject.mirror_was_hard_failed(project) }

        around do |example|
          perform_enqueued_jobs { example.run }
        end
      end

      context 'when owner is blocked' do
        it 'does not send email' do
          project.owner.block!

          expect(Notify).not_to receive(:mirror_was_hard_failed_email)

          subject.mirror_was_hard_failed(project)
        end

        context 'when project belongs to group' do
          it 'does not send email to the blocked owner' do
            blocked_user = create(:user, :blocked)

            group = create(:group, :public)
            group.add_owner(blocked_user)
            group.add_owner(user)

            project = create(:project, :mirror, :import_hard_failed, namespace: group)

            expect(Notify).not_to receive(:mirror_was_hard_failed_email).with(project.id, blocked_user.id).and_call_original
            expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

            subject.mirror_was_hard_failed(project)
          end
        end
      end
    end

    context 'when user is maintainer' do
      it 'sends email' do
        project = create(:project, :mirror, :import_hard_failed)
        project.add_maintainer(user)

        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.first_owner.id).and_call_original
        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end
    end

    context 'when user is not owner nor maintainer' do
      it 'does not send email' do
        project = create(:project, :mirror, :import_hard_failed)
        project.add_developer(user)

        expect(Notify).not_to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original
        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.creator.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end

      context 'when user is group owner' do
        it 'sends email' do
          group = create(:group, :public) do |group|
            group.add_owner(user)
          end

          project = create(:project, :mirror, :import_hard_failed, namespace: group)

          expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

          subject.mirror_was_hard_failed(project)
        end
      end

      context 'when user is group maintainer' do
        it 'sends email' do
          group = create(:group, :public) do |group|
            group.add_maintainer(user)
          end

          project = create(:project, :mirror, :import_hard_failed, namespace: group)

          expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

          subject.mirror_was_hard_failed(project)
        end
      end
    end
  end

  describe 'mirror was disabled' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    let(:deleted_username) { 'deleted_user_name' }

    context 'when the project has invited members' do
      let!(:project_member) { create(:project_member, :invited, project: project) }

      it 'sends email' do
        expect(Notify).to receive(:mirror_was_disabled_email).with(project.id, project.first_owner.id, deleted_username).and_call_original

        subject.mirror_was_disabled(project, deleted_username)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { subject.mirror_was_disabled(project, deleted_username) }

        around do |example|
          perform_enqueued_jobs { example.run }
        end
      end
    end

    context 'when user is owner' do
      it 'sends email' do
        expect(Notify).to receive(:mirror_was_disabled_email).with(project.id, project.first_owner.id, deleted_username).and_call_original

        subject.mirror_was_disabled(project, deleted_username)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { subject.mirror_was_disabled(project, deleted_username) }

        around do |example|
          perform_enqueued_jobs { example.run }
        end
      end

      context 'when owner is blocked' do
        it 'does not send email' do
          project.owner.block!

          expect(Notify).not_to receive(:mirror_was_disabled_email)

          subject.mirror_was_disabled(project, deleted_username)
        end

        context 'when project belongs to group' do
          it 'does not send email to the blocked owner' do
            blocked_user = create(:user, :blocked)

            group = create(:group, :public)
            group.add_owner(blocked_user)
            group.add_owner(user)

            project = create(:project, namespace: group)

            expect(Notify).not_to receive(:mirror_was_disabled_email).with(project.id, blocked_user.id, deleted_username).and_call_original
            expect(Notify).to receive(:mirror_was_disabled_email).with(project.id, user.id, deleted_username).and_call_original

            subject.mirror_was_disabled(project, deleted_username)
          end
        end
      end
    end

    context 'when user is maintainer' do
      it 'sends email' do
        project.add_maintainer(user)

        expect(Notify).to receive(:mirror_was_disabled_email).with(project.id, project.first_owner.id, deleted_username).and_call_original
        expect(Notify).to receive(:mirror_was_disabled_email).with(project.id, user.id, deleted_username).and_call_original

        subject.mirror_was_disabled(project, deleted_username)
      end
    end

    context 'when user is not owner nor maintainer' do
      it 'does not send email' do
        project.add_developer(user)

        expect(Notify).not_to receive(:mirror_was_disabled_email).with(project.id, user.id, deleted_username).and_call_original
        expect(Notify).to receive(:mirror_was_disabled_email).with(project.id, project.creator.id, deleted_username).and_call_original

        subject.mirror_was_disabled(project, deleted_username)
      end

      context 'when user is group owner' do
        it 'sends email' do
          group = create(:group, :public) do |group|
            group.add_owner(user)
          end

          project = create(:project, namespace: group)

          expect(Notify).to receive(:mirror_was_disabled_email).with(project.id, user.id, deleted_username).and_call_original

          subject.mirror_was_disabled(project, deleted_username)
        end
      end

      context 'when user is group maintainer' do
        it 'sends email' do
          group = create(:group, :public) do |group|
            group.add_maintainer(user)
          end

          project = create(:project, namespace: group)

          expect(Notify).to receive(:mirror_was_disabled_email).with(project.id, user.id, deleted_username).and_call_original

          subject.mirror_was_disabled(project, deleted_username)
        end
      end
    end
  end

  context 'mirror user changed' do
    let(:mirror_user) { create(:user) }
    let(:project) { create(:project, :mirror, mirror_user_id: mirror_user.id) }
    let(:new_mirror_user) { project.team.owners.first }

    it 'sends email' do
      expect(Notify).to receive(:project_mirror_user_changed_email).with(new_mirror_user.id, mirror_user.name, project.id).and_call_original

      subject.project_mirror_user_changed(new_mirror_user, mirror_user.name, project)
    end

    it_behaves_like 'project emails are disabled' do
      let(:notification_target)  { project }
      let(:notification_trigger) { subject.project_mirror_user_changed(new_mirror_user, mirror_user.name, project) }

      around do |example|
        perform_enqueued_jobs { example.run }
      end
    end
  end

  describe 'issues' do
    let(:group) { create(:group) }
    let(:project) { create(:project, :public, namespace: group) }
    let(:assignee) { create(:user) }

    let(:issue) { create :issue, project: project, assignees: [assignee], description: 'cc @participant @unsubscribed_mentioned' }

    let(:notification) { NotificationService.new }

    before do
      build_group_members(group)

      add_users_with_subscription(group, issue)
      reset_delivered_emails!
    end

    around do |example|
      perform_enqueued_jobs { example.run }
    end

    shared_examples 'altered iteration notification on issue' do
      it 'sends the email to the correct people' do
        should_email(subscriber_to_new_iteration)
        issue.assignees.each do |a|
          should_email(a)
        end
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@subscribed_participant)
        should_email(@watcher_and_subscriber)
        should_not_email(@u_guest_custom)
        should_not_email(@u_committer)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_lazy_participant)
        should_not_email(issue.author)
        should_not_email(@u_disabled)
        should_not_email(@u_custom_global)
        should_not_email(@u_mentioned)
      end
    end

    describe '#removed_iteration_issue' do
      let(:mailer_method) { :removed_iteration_issue_email }

      context do
        let(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group), issues: [issue]) }
        let!(:subscriber_to_new_iteration) { create(:user) { |u| issue.toggle_subscription(u, project) } }

        it_behaves_like 'altered iteration notification on issue' do
          before do
            notification.removed_iteration_issue(issue, issue.author)
          end
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { issue }
          let(:notification_trigger) { notification.removed_iteration_issue(issue, issue.author) }
        end
      end

      context 'confidential issues' do
        let(:author) { create(:user) }
        let(:assignee) { create(:user) }
        let(:non_member) { create(:user) }
        let(:member) { create(:user) }
        let(:guest) { create(:user) }
        let(:admin) { create(:admin) }
        let(:confidential_issue) { create(:issue, :confidential, project: project, title: 'Confidential issue', author: author, assignees: [assignee]) }
        let(:iteration) { create(:iteration, issues: [confidential_issue]) }

        it "emails subscribers of the issue's iteration that can read the issue" do
          project.add_developer(member)
          project.add_guest(guest)

          confidential_issue.subscribe(non_member, project)
          confidential_issue.subscribe(author, project)
          confidential_issue.subscribe(assignee, project)
          confidential_issue.subscribe(member, project)
          confidential_issue.subscribe(guest, project)
          confidential_issue.subscribe(admin, project)

          reset_delivered_emails!

          notification.removed_iteration_issue(confidential_issue, @u_disabled)

          should_not_email(non_member)
          should_not_email(guest)
          should_email(author)
          should_email(assignee)
          should_email(member)
          should_email(admin)
        end
      end
    end

    describe '#changed_iteration_issue' do
      let(:mailer_method) { :changed_iteration_issue_email }

      context do
        let(:new_iteration) { create(:iteration, issues: [issue]) }
        let!(:subscriber_to_new_iteration) { create(:user) { |u| issue.toggle_subscription(u, project) } }

        it_behaves_like 'altered iteration notification on issue' do
          before do
            notification.changed_iteration_issue(issue, new_iteration, issue.author)
          end
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { issue }
          let(:notification_trigger) { notification.changed_iteration_issue(issue, new_iteration, issue.author) }
        end
      end

      context 'confidential issues' do
        let(:author) { create(:user) }
        let(:assignee) { create(:user) }
        let(:non_member) { create(:user) }
        let(:member) { create(:user) }
        let(:guest) { create(:user) }
        let(:admin) { create(:admin) }
        let(:confidential_issue) { create(:issue, :confidential, project: project, title: 'Confidential issue', author: author, assignees: [assignee]) }
        let(:new_iteration) { create(:iteration, issues: [confidential_issue]) }

        it "emails subscribers of the issue's iteration that can read the issue" do
          project.add_developer(member)
          project.add_guest(guest)

          confidential_issue.subscribe(non_member, project)
          confidential_issue.subscribe(author, project)
          confidential_issue.subscribe(assignee, project)
          confidential_issue.subscribe(member, project)
          confidential_issue.subscribe(guest, project)
          confidential_issue.subscribe(admin, project)

          reset_delivered_emails!

          notification.changed_iteration_issue(confidential_issue, new_iteration, @u_disabled)

          should_not_email(non_member)
          should_not_email(guest)
          should_email(author)
          should_email(assignee)
          should_email(member)
          should_email(admin)
        end
      end
    end
  end

  describe 'epics' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:epic) { create(:epic, group: group) }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    before do
      stub_licensed_features(epics: true)
      group.add_developer(epic.author)
    end

    context 'epic notes' do
      let(:note) { create(:note, project: nil, noteable: epic, note: '@mention referenced, @unsubscribed_mentioned and @outsider also') }

      before do
        build_group_members(group)

        @u_custom_off = create_user_with_notification(:custom, 'custom_off', group)
        create(:group_member, group: group, user: @u_custom_off)

        create(
          :note,
          project: nil,
          noteable: epic,
          author: @u_custom_off,
          note: 'i think @subscribed_participant should see this'
        )

        update_custom_notification(:new_note, @u_guest_custom, resource: group)
        update_custom_notification(:new_note, @u_custom_global)
        add_users_with_subscription(group, epic)
      end

      describe '#new_note' do
        specify do
          reset_delivered_emails!

          expect(SentNotification).to receive(:record).with(epic, any_args).exactly(9).times

          subject.new_note(note)

          should_email(@u_watcher)
          should_email(note.noteable.author)
          should_email(@u_custom_global)
          should_email(@u_mentioned)
          should_email(@subscriber)
          should_email(@watcher_and_subscriber)
          should_email(@subscribed_participant)
          should_email(@u_custom_off)
          should_email(@unsubscribed_mentioned)
          should_not_email(@u_guest_custom)
          should_not_email(@u_guest_watcher)
          should_not_email(note.author)
          should_not_email(@u_participating)
          should_not_email(@u_disabled)
          should_not_email(@unsubscriber)
          should_not_email(@u_outsider_mentioned)
          should_not_email(@u_lazy_participant)

          expect(find_email_for(@u_mentioned)).to have_header('X-GitLab-NotificationReason', 'mentioned')
          expect(find_email_for(@u_custom_global)).to have_header('X-GitLab-NotificationReason', '')
        end

        it_behaves_like 'group emails are disabled' do
          let(:notification_target)  { epic.group }
          let(:notification_trigger) { subject.new_note(note) }
        end
      end
    end

    shared_examples 'epic notifications' do
      let(:watcher) { create(:user) }
      let(:participating) { create(:user) }
      let(:other_user) { create(:user) }

      before do
        create_global_setting_for(watcher, :watch)
        create_global_setting_for(participating, :participating)

        group.add_developer(watcher)
        group.add_developer(participating)
        group.add_developer(other_user)

        reset_delivered_emails!
      end

      it 'sends notification to watcher when no user participates' do
        execute

        should_email(watcher)
        should_not_email(participating)
        should_not_email(other_user)
      end

      it 'sends notification to watcher and a participator' do
        epic.subscriptions.create!(user: participating, subscribed: true)

        execute

        should_email(watcher)
        should_email(participating)
        should_not_email(other_user)
      end

      it_behaves_like 'group emails are disabled' do
        let(:notification_target)  { epic.group }
        let(:notification_trigger) { execute }
      end
    end

    context 'close epic' do
      let(:execute) { subject.close_epic(epic, epic.author) }

      include_examples 'epic notifications'
    end

    context 'reopen epic' do
      let(:execute) { subject.reopen_epic(epic, epic.author) }

      include_examples 'epic notifications'
    end

    context 'new epic' do
      let(:current_user) { epic.author }
      let(:execute) { subject.new_epic(epic, current_user) }

      include_examples 'epic notifications'

      shared_examples 'is not able to send notifications' do
        it 'does not send any notification' do
          expect(Gitlab::AppLogger).to receive(:warn).with(message: 'Skipping sending notifications', user: current_user.id, klass: epic.class.to_s, object_id: epic.id)

          execute

          should_not_email(watcher)
          should_not_email(participating)
          should_not_email(other_user)
        end
      end

      context 'when author is not confirmed' do
        let(:current_user) { create(:user, :unconfirmed) }

        include_examples 'is not able to send notifications'
      end

      context 'when author is blocked' do
        let(:current_user) { create(:user, :blocked) }

        include_examples 'is not able to send notifications'
      end

      context 'when author is a ghost' do
        let(:current_user) { create(:user, :ghost) }

        include_examples 'is not able to send notifications'
      end
    end
  end

  def build_group_members(group)
    @u_watcher               = create_global_setting_for(create(:user), :watch)
    @u_participating         = create_global_setting_for(create(:user), :participating)
    @u_participant_mentioned = create_global_setting_for(create(:user, username: 'participant'), :participating)
    @u_disabled              = create_global_setting_for(create(:user), :disabled)
    @u_mentioned             = create_global_setting_for(create(:user, username: 'mention'), :mention)
    @u_committer             = create(:user, username: 'committer')
    @u_not_mentioned         = create_global_setting_for(create(:user, username: 'regular'), :participating)
    @u_outsider_mentioned    = create(:user, username: 'outsider')
    @u_custom_global         = create_global_setting_for(create(:user, username: 'custom_global'), :custom)

    # User to be participant by default
    # This user does not contain any record in notification settings table
    # It should be treated with a :participating notification_level
    @u_lazy_participant = create(:user, username: 'lazy-participant')

    @u_guest_watcher = create_user_with_notification(:watch, 'guest_watching', group)
    @u_guest_custom = create_user_with_notification(:custom, 'guest_custom', group)

    create(:group_member, group: group, user: @u_watcher)
    create(:group_member, group: group, user: @u_participating)
    create(:group_member, group: group, user: @u_participant_mentioned)
    create(:group_member, group: group, user: @u_disabled)
    create(:group_member, group: group, user: @u_mentioned)
    create(:group_member, group: group, user: @u_committer)
    create(:group_member, group: group, user: @u_not_mentioned)
    create(:group_member, group: group, user: @u_lazy_participant)
    create(:group_member, group: group, user: @u_custom_global)
  end

  def add_users_with_subscription(group, issuable)
    @subscriber = create :user
    @unsubscriber = create :user
    @unsubscribed_mentioned = create :user, username: 'unsubscribed_mentioned'
    @subscribed_participant = create_global_setting_for(create(:user, username: 'subscribed_participant'), :participating)
    @watcher_and_subscriber = create_global_setting_for(create(:user), :watch)

    create(:group_member, group: group, user: @subscribed_participant)
    create(:group_member, group: group, user: @subscriber)
    create(:group_member, group: group, user: @unsubscriber)
    create(:group_member, group: group, user: @watcher_and_subscriber)
    create(:group_member, group: group, user: @unsubscribed_mentioned)

    issuable.subscriptions.create!(user: @unsubscribed_mentioned, subscribed: false)
    issuable.subscriptions.create!(user: @subscriber, subscribed: true)
    issuable.subscriptions.create!(user: @subscribed_participant, subscribed: true)
    issuable.subscriptions.create!(user: @unsubscriber, subscribed: false)
    # Make the watcher a subscriber to detect dupes
    issuable.subscriptions.create!(user: @watcher_and_subscriber, subscribed: true)
  end

  context 'Merge Requests' do
    let(:notification) { NotificationService.new }
    let(:assignee) { create(:user) }
    let(:assignee2) { create(:user) }
    let(:group) { create(:group) }
    let(:project) { create(:project, :public, :repository, namespace: group) }
    let(:another_project) { create(:project, :public, namespace: group) }
    let(:merge_request) { create :merge_request, source_project: project, assignees: [assignee, assignee2], description: 'cc @participant' }

    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    before do
      project.add_maintainer(merge_request.author)
      merge_request.assignees.each { |assignee| project.add_maintainer(assignee) }
      build_team(merge_request.target_project)
      add_users_with_subscription(merge_request.target_project, merge_request)
      update_custom_notification(:new_merge_request, @u_guest_custom, resource: project)
      update_custom_notification(:new_merge_request, @u_custom_global)
      reset_delivered_emails!
    end

    describe '#new_merge_request' do
      it 'emails all assignees' do
        notification.new_merge_request(merge_request, assignee)

        merge_request.assignees.each { |assignee| should_email(assignee) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.new_merge_request(merge_request, assignee) }
      end

      context 'when the target project has approvers set' do
        let(:project_approvers) { create_list(:user, 3) }
        let!(:rule) { create(:approval_project_rule, project: project, users: project_approvers, approvals_required: 1 ) }

        before do
          reset_delivered_emails!
        end

        it 'does not email the approvers' do
          notification.new_merge_request(merge_request, @u_disabled)

          project_approvers.each { |approver| should_not_email(approver) }
        end

        it 'does not email the approvers when approval is not necessary' do
          project.approval_rules.update_all(approvals_required: 0)
          notification.new_merge_request(merge_request, @u_disabled)

          project_approvers.each { |approver| should_not_email(approver) }
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { merge_request }
          let(:notification_trigger) { notification.new_merge_request(merge_request, @u_disabled) }
        end

        context 'when the merge request has approvers set' do
          let(:mr_approvers) { create_list(:user, 3) }
          let!(:mr_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: mr_approvers, approvals_required: 1 ) }

          before do
            reset_delivered_emails!
          end

          it 'does not email the MR approvers' do
            notification.new_merge_request(merge_request, @u_disabled)

            mr_approvers.each { |approver| should_not_email(approver) }
          end

          it 'does not email approvers set on the project who are not approvers of this MR' do
            notification.new_merge_request(merge_request, @u_disabled)

            project_approvers.each { |approver| should_not_email(approver) }
          end

          it_behaves_like 'project emails are disabled' do
            let(:notification_target)  { merge_request }
            let(:notification_trigger) { notification.new_merge_request(merge_request, @u_disabled) }
          end
        end
      end
    end

    def build_team(project)
      @u_watcher               = create_global_setting_for(create(:user), :watch)
      @u_participating         = create_global_setting_for(create(:user), :participating)
      @u_participant_mentioned = create_global_setting_for(create(:user, username: 'participant'), :participating)
      @u_disabled              = create_global_setting_for(create(:user), :disabled)
      @u_mentioned             = create_global_setting_for(create(:user, username: 'mention'), :mention)
      @u_committer             = create(:user, username: 'committer')
      @u_not_mentioned         = create_global_setting_for(create(:user, username: 'regular'), :participating)
      @u_outsider_mentioned    = create(:user, username: 'outsider')
      @u_custom_global         = create_global_setting_for(create(:user, username: 'custom_global'), :custom)

      # User to be participant by default
      # This user does not contain any record in notification settings table
      # It should be treated with a :participating notification_level
      @u_lazy_participant = create(:user, username: 'lazy-participant')

      @u_guest_watcher = create_user_with_notification(:watch, 'guest_watching')
      @u_guest_custom = create_user_with_notification(:custom, 'guest_custom')

      [@u_watcher, @u_participating, @u_participant_mentioned, @u_disabled, @u_mentioned, @u_committer, @u_not_mentioned, @u_lazy_participant, @u_custom_global].each do |user|
        project.add_maintainer(user)
      end
    end

    def add_users_with_subscription(project, issuable)
      @subscriber = create :user
      @unsubscriber = create :user
      @unsubscribed_mentioned = create :user, username: 'unsubscribed_mentioned'
      @subscribed_participant = create_global_setting_for(create(:user, username: 'subscribed_participant'), :participating)
      @watcher_and_subscriber = create_global_setting_for(create(:user), :watch)

      [@subscribed_participant, @subscriber, @unsubscriber, @watcher_and_subscriber, @unsubscribed_mentioned].each do |user|
        project.add_maintainer(user)
      end

      issuable.subscriptions.create!(user: @unsubscribed_mentioned, project: project, subscribed: false)
      issuable.subscriptions.create!(user: @subscriber, project: project, subscribed: true)
      issuable.subscriptions.create!(user: @subscribed_participant, project: project, subscribed: true)
      issuable.subscriptions.create!(user: @unsubscriber, project: project, subscribed: false)
      # Make the watcher a subscriber to detect dupes
      issuable.subscriptions.create!(user: @watcher_and_subscriber, project: project, subscribed: true)
    end
  end

  context 'Members' do
    describe '#new_group_member_with_confirmation' do
      let(:added_user) { create(:user) }
      let(:group) { create(:group) }

      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      before do
        reset_delivered_emails!
        added_user.user_detail.update!(provisioned_by_group_id: group.id)
      end

      it 'sends a notification' do
        group.add_guest(added_user)
        should_only_email(added_user)
      end
    end
  end

  context 'IncidentManagement' do
    let_it_be(:user) { create(:user) }

    describe '#notify_oncall_users_of_alert' do
      let_it_be(:alert) { create(:alert_management_alert) }
      let_it_be(:project) { alert.project }

      let(:tracking_params) do
        {
          event_names: 'i_incident_management_oncall_notification_sent',
          start_date: 1.week.ago,
          end_date: 1.week.from_now
        }
      end

      it 'sends an email to the specified users' do
        expect(Notify).to receive(:prometheus_alert_fired_email).with(project, user, alert).and_call_original

        subject.notify_oncall_users_of_alert([user], alert)
      end

      it 'tracks a count of unique recipients', :clean_gitlab_redis_shared_state do
        expect { subject.notify_oncall_users_of_alert([user], alert) }
          .to change { Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(**tracking_params) }
          .by 1
      end
    end

    describe '#oncall_user_removed' do
      let_it_be(:schedule) { create(:incident_management_oncall_schedule) }
      let_it_be(:rotation) { create(:incident_management_oncall_rotation, schedule: schedule) }
      let_it_be(:participant) { create(:incident_management_oncall_participant, rotation: rotation) }

      it 'sends an email to the owner and participants' do
        expect(Notify).to receive(:user_removed_from_rotation_email).with(user, rotation, [schedule.project.first_owner]).once.and_call_original
        expect(Notify).to receive(:user_removed_from_rotation_email).with(user, rotation, [participant.user]).once.and_call_original

        subject.oncall_user_removed(rotation, user)
      end

      it 'sends the email inline when async = false' do
        expect { subject.oncall_user_removed(rotation, user, false) }.to change(ActionMailer::Base.deliveries, :size).by(2)
      end
    end

    describe '#user_escalation_rule_deleted' do
      let(:project) { create(:project) }
      let(:user) { create(:user) }
      let(:rules) { [rule_1, rule_2] }
      let!(:rule_1) { create(:incident_management_escalation_rule, :with_user, project: project, user: user) }
      let!(:rule_2) { create(:incident_management_escalation_rule, :with_user, :resolved, project: project, user: user) }

      it 'immediately sends an email to the project owner' do
        expect(Notify).to receive(:user_escalation_rule_deleted_email).with(user, project, rules, project.first_owner).once.and_call_original
        expect(Notify).not_to receive(:user_escalation_rule_deleted_email).with(user, project, rules, user)

        expect { subject.user_escalation_rule_deleted(project, user, rules) }.to change(ActionMailer::Base.deliveries, :size).by(1)
      end

      context 'when project owner is the removed user' do
        let(:user) { project.first_owner }

        it 'does not send an email' do
          expect(Notify).not_to receive(:user_escalation_rule_deleted_email)

          subject.user_escalation_rule_deleted(project, user, rules)
        end
      end

      context 'with a group' do
        let(:group) { create(:group) }
        let(:project) { create(:project, group: group) }
        let(:owner) { create(:user) }
        let(:blocked_owner) { create(:user, :blocked) }

        before do
          group.add_owner(owner)
          group.add_owner(blocked_owner)
          group.add_owner(user)
        end

        it 'immediately sends an email to the eligable project owners' do
          expect(Notify).to receive(:user_escalation_rule_deleted_email).with(user, project, rules, owner).once.and_call_original
          expect(Notify).not_to receive(:user_escalation_rule_deleted_email).with(user, project, rules, blocked_owner)
          expect(Notify).not_to receive(:user_escalation_rule_deleted_email).with(user, project, rules, user)

          expect { subject.user_escalation_rule_deleted(project, user, rules) }.to change(ActionMailer::Base.deliveries, :size).by(1)
        end
      end
    end
  end

  describe '#pipeline_finished' do
    let_it_be(:project, reload: true) { create(:project, :repository) }

    let(:user) { create(:user, email_opted_in: true) }
    let(:has_required_credit_card_to_run_pipelines) { false }
    let(:failure_reason) { 'user_not_verified' }
    let(:pipeline) do
      create(
        :ci_empty_pipeline,
        project: project,
        ref: 'master',
        status: 'failed',
        failure_reason: failure_reason,
        sha: project.commit.id,
        user: user
      )
    end

    subject(:pipeline_finished) { NotificationService.new.pipeline_finished(pipeline) }

    before do
      allow(::Gitlab).to receive(:com?).and_return(true)
      allow(user).to receive(:has_required_credit_card_to_run_pipelines?).and_return(has_required_credit_card_to_run_pipelines)

      project.add_maintainer(user)
    end

    shared_examples 'does not send account activation email' do
      it 'does not send account activation email' do
        expect(Notify).not_to receive(:account_validation_email)

        pipeline_finished
      end
    end

    context 'with a failed pipeline' do
      it 'sends account activation email' do
        expect(Notify).to receive(:account_validation_email).with(pipeline, user.notification_email_or_default).once.and_call_original

        pipeline_finished
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(account_validation_email: false)
        end

        include_examples 'does not send account activation email'
      end

      context 'when not in dev env or gitlab.com' do
        before do
          allow(::Gitlab).to receive(:com?).and_return(false)
        end

        include_examples 'does not send account activation email'
      end

      context 'when user is not opted in to marketing emails' do
        let(:user) { create(:user, email_opted_in: false) }

        include_examples 'does not send account activation email'
      end

      context "when failure reason is not user_not_verified" do
        let(:failure_reason) { 'unknown_failure' }

        include_examples 'does not send account activation email'
      end

      context 'when user account is validated' do
        let(:has_required_credit_card_to_run_pipelines) { true }

        include_examples 'does not send account activation email'
      end

      context 'when user cannot receive notifications' do
        let(:user) { User.ghost }

        include_examples 'does not send account activation email'
      end
    end
  end
end
