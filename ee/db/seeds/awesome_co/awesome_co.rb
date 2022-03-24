# frozen_string_literal: true

module AwesomeCo
  def self.seed(owner)
    AwesomeCo.new(owner).seed
  end

  class AwesomeCo
    include FactoryBot::Syntax::Methods

    def initialize(owner)
      @owner = owner
      @namespace = create(:group, name: 'Awesome Co', path: "awesome-co-#{owner.username}-#{SecureRandom.hex(3)}")
      @namespace.add_owner(owner)

      @labels = {
        priority_1: create(:group_label, group: namespace, title: 'priority::1', color: '#FF0000'),
        priority_2: create(:group_label, group: namespace, title: 'priority::2', color: '#DD0000'),
        priority_3: create(:group_label, group: namespace, title: 'priority::3', color: '#CC0000'),
        priority_4: create(:group_label, group: namespace, title: 'priority::4', color: '#CC1111'),

        squad_a: create(:group_label, group: namespace, title: 'squad::a', color: '#CCCCCC'),
        squad_b: create(:group_label, group: namespace, title: 'squad::b', color: '#CCCCCC'),
        squad_c: create(:group_label, group: namespace, title: 'squad::c', color: '#CCCCCC'),
        squad_d: create(:group_label, group: namespace, title: 'squad::d', color: '#CCCCCC'),
        squad_e: create(:group_label, group: namespace, title: 'squad::e', color: '#CCCCCC'),
        squad_f: create(:group_label, group: namespace, title: 'squad::f', color: '#CCCCCC'),

        type_0_idea: create(:group_label, group: namespace, title: 'type::0-idea', color: '#00CC00'),
        type_1_epic: create(:group_label, group: namespace, title: 'type::1-epic', color: '#00CC00'),
        type_2_capability: create(:group_label, group: namespace, title: 'type::2-capability', color: '#00CC00'),
        type_3_feature: create(:group_label, group: namespace, title: 'type::3-feature', color: '#00CC00'),
        type_4_bug: create(:group_label, group: namespace, title: 'type::4-bug', color: '#00DD00'),
        type_4_maintenance: create(:group_label, group: namespace, title: 'type::4-maintenance', color: '#00DD00'),
        type_4_story: create(:group_label, group: namespace, title: 'type::4-story', color: '#00DD00'),
        type_4_task: create(:group_label, group: namespace, title: 'type::4-task', color: '#00DD00'),

        wf_1_triage: create(:group_label, group: namespace, title: 'wf::1-triage', color: '#DDDDDD'),
        wf_2_design: create(:group_label, group: namespace, title: 'wf::2-design', color: '#DDDDDD'),
        wf_3_validation: create(:group_label, group: namespace, title: 'wf::3-validation', color: '#DDDDDD'),
        wf_4_refine: create(:group_label, group: namespace, title: 'wf::4-refine', color: '#DDDDDD'),
        wf_5_ready: create(:group_label, group: namespace, title: 'wf::5-ready', color: '#DDDDDD'),
        wf_6_in_progress: create(:group_label, group: namespace, title: 'wf::6-in progress', color: '#CCCCCC'),
        wf_7_review: create(:group_label, group: namespace, title: 'wf::7-review', color: '#CCCCCC'),
        wf_8_done: create(:group_label, group: namespace, title: 'wf::8-done', color: '#CCCCCC'),

        version_1: create(:group_label, group: namespace, title: 'version::1.0', color: '#00FD00'),
        version_1_1: create(:group_label, group: namespace, title: 'version::1.1', color: '#0000FD'),

        capability_1_refine: create(:group_label,
                                    group: namespace,
                                    title: 'capability::1-refine',
                                    description: 'Capability is currently in refinement',
                                    color: '#000022'),
        capability_2_review: create(:group_label,
                                    group: namespace,
                                    title: 'capability::2-review',
                                    description: 'Capability is in the review and approval process',
                                    color: '#000022'),
        capability_3_backlog: create(:group_label,
                                    group: namespace,
                                    title: 'capability::3-backlog',
                                    description: 'Capability is approved and waiting to be started',
                                    color: '#000022'),
        capability_4_in_progress: create(:group_label,
                                    group: namespace,
                                    title: 'capability::4-in progress',
                                    description: 'Capability is currently under development',
                                    color: '#000022'),
        comp_auth: create(:group_label,
                          group: namespace,
                          title: 'comp::auth',
                          description: 'The work item is related to the authentication components',
                          color: '#6699CC'),
        comp_infra: create(:group_label,
                          group: namespace,
                          title: 'comp::infra',
                          description: 'The work item is related to the authentication components',
                          color: '#6699CC'),
        comp_login: create(:group_label,
                          group: namespace,
                          title: 'comp::login',
                          description: 'The work item is related to the authentication components',
                          color: '#6699CC'),
        comp_settings: create(:group_label,
                          group: namespace,
                          title: 'comp::settings',
                          description: 'The work item is related to the authentication components',
                          color: '#6699CC'),

        effort_l: create(:group_label,
                          group: namespace,
                          title: 'effort::l',
                          description: 'The effort for this epic is large',
                          color: '#808080'),
        effort_m: create(:group_label,
                          group: namespace,
                          title: 'effort::m',
                          description: 'The effort for this epic is medium',
                          color: '#808080'),
        effort_s: create(:group_label,
                          group: namespace,
                          title: 'effort::s',
                          description: 'The effort for this epic is small',
                          color: '#808080'),
        effort_xl: create(:group_label,
                          group: namespace,
                          title: 'effort::xl',
                          description: 'The effort for this epic is extra large',
                          color: '#808080')
      }

      @milestones = {
        release_1: create(:milestone,
                          :on_group,
                          group: namespace,
                          title: 'Release #1',
                          start_date: 1.month.ago,
                          due_date: 1.day.ago),
        release_2: create(:milestone,
                          :on_group,
                          group: namespace,
                          title: 'Release #2',
                          start_date: 1.day.ago,
                          due_date: 1.day.ago + 1.month),
        release_3: create(:milestone,
                          :on_group,
                          group: namespace,
                          title: 'Release #3',
                          start_date: 1.month.from_now,
                          due_date: 2.months.from_now),
        release_4: create(:milestone,
                          :on_group,
                          group: namespace,
                          title: 'Release #4',
                          start_date: 2.months.from_now,
                          due_date: 3.months.from_now)
      }

      @epics = {
        v10_launch: create(:epic,
                           group: namespace,
                           title: 'v1.0 Launch [XL]',
                           description: <<~MARKDOWN, labels: [labels[:effort_xl], labels[:type_1_epic]], author: owner)
                             # MVC

                             A user can create an account, login and modify their settings

                             # Stand up infra

                             - [ ] Standup infra `10`
                             - [x] Task
                             - [ ] Key Result
                             - [ ] Task 2
                             - [ ] Task 3
                           MARKDOWN
      }
    end

    # Seed AwesomeCo data
    # @return [Namespace] the root namespace used for seeding
    def seed
      create_logistics
      create_alliances
      create_consumer_products
      create_services
      create_ideas
      create_ops

      namespace
    end

    private

    attr_reader :owner, :namespace, :labels, :milestones, :epics

    # Logistics Subgroup
    def create_logistics
      create(:group, name: 'Logistics', parent: namespace).tap do |group|
        create(:milestone, :on_group, title: 'Logistics Milestone', group: group)

        v11_launch_epic = create(:epic, group: group, title: 'v1.1 Launch [XL]', author: owner)
        update_website_epic = create(:epic,
                                     group: group,
                                     title: 'Update the Website to reflect our Newest Release',
                                     author: owner,
                                     parent: v11_launch_epic)

        iterations = {
          logistics: create(:iteration, :with_title, :current, title: 'Logistics Iteration', group: group),
          manual: create(:iteration, :with_title, :current, title: 'Manual', group: group),
          squad_a: create(:iteration, :with_title, :current, title: 'Squad A', group: group),
          squad_b: create(:iteration, :with_title, :current, title: 'Squad B', group: group)
        }

        # Squad C
        create(:project, :public, name: 'Squad C', namespace: group, creator: owner).tap do |project|
          i = create(:issue,
                     title: 'Adjust Text on Homepage to reflect new brand messaging',
                     project: project,
                     milestone: milestones[:release_2],
                     iteration: iterations[:squad_a],
                     labels: [labels[:type_4_story], labels[:wf_1_triage]],
                     weight: 5,
                     due_date: Date.yesterday + 1.month,
                     health_status: :on_track,
                     assignees: [owner],
                     description: <<~MARKDOWN)
                       ## Proposal

                       Adjust Text on Homepage to reflect new brand messaging

                       ## Acceptance Criteria

                       - [x] As a user, I can see the banner on Windows OS
                       - [ ] As a user, I can see the banner on MacOS
                       - [ ] As a user, I can see the banner on iOS
                       - [ ] As a user, I can see the banner on Android

                       ## Implementation Steps

                       - [x] Brand has approved design
                       - [ ] Deployment has been confirmed
                       - [ ] File added to repo
                       - [ ] Approved by PM
                     MARKDOWN
          create(:timelog, issue: i, time_spent: 30) # 30 minutes
          create(:epic_issue, epic: update_website_epic, issue: i)

          create(:epic_issue,
                 epic: update_website_epic,
                 issue: create(:issue,
                               project: project,
                               milestone: milestones[:release_2],
                               title: 'A few broken links in homepage detected',
                               labels: [
                                 labels[:priority_4],
                                 labels[:type_4_bug]
                               ],
                               weight: 1,
                               health_status: :on_track,
                               description: <<~MARKDOWN))
                                 There are some broken links on the homepage that need to be adjusted
                               MARKDOWN

          create(:epic_issue,
                 epic: update_website_epic,
                 issue: create(:issue,
                               project: project,
                               milestone: milestones[:release_2],
                               title: 'log-in box disappeared for certain users',
                               labels: [labels[:priority_1], labels[:type_4_bug]],
                               weight: 5,
                               health_status: :needs_attention,
                               description: <<~MARKDOWN))
                                 The log-in box has been reported as disappearing for certain users using MacOS Monterey
                               MARKDOWN

          create(:epic_issue,
                 epic: update_website_epic,
                 issue: create(:issue,
                               project: project,
                               milestone: milestones[:release_2],
                               title: 'The catalog page response time is slow',
                               labels: [labels[:type_4_bug], labels[:wf_1_triage]],
                               weight: 13,
                               time_estimate: 1.hour.to_i,
                               health_status: :at_risk,
                               description: <<~MARKDOWN))
                                 ## Current Behavior

                                 1. Users have reported the response time to be slow

                                 ## Steps to Reproduce

                                 1. Test with MacOS Monterey

                                 ## Expected Behavior

                                 1. Response times to be at standard
                               MARKDOWN

          create(:issue,
                 project: project,
                 milestone: milestones[:release_2],
                 title: 'add job to clean resources from the cluster (review apps)',
                 weight: 3,
                 health_status: :on_track)
          create(:epic_issue,
                 epic: update_website_epic,
                 issue: create(:issue,
                               project: project,
                               milestone: milestones[:release_2],
                               title: 'A few users complained that the chat bot disconnects during a chat session',
                               weight: 5,
                               health_status: :on_track))
          create(:epic_issue,
                 epic: update_website_epic,
                 issue: create(:issue,
                               :closed,
                               project: project,
                               milestone: milestones[:release_2],
                               title: 'CPU threshold exceeded on rails-fe-node-4',
                               weight: 7,
                               health_status: :on_track))
        end
      end
    end

    # Alliances Subgroup
    def create_alliances
      create(:group, name: 'Alliances', parent: namespace).tap do |group|
        create(:project, :public, name: 'Squad E', namespace: group, creator: owner)
        create(:project, :public, name: 'Squad F', namespace: group, creator: owner)
      end
    end

    # Consumer Products
    def create_consumer_products
      create(:group, name: 'Consumer Products', parent: namespace).tap do |group|
        group_epics = {
          mobile_app_v10_interface: create(:epic,
                                           group: group,
                                           title: 'Mobile App v1.0 Interface',
                                           labels: [
                                             labels[:capability_4_in_progress],
                                             labels[:effort_m],
                                             labels[:type_2_capability]
                                           ],
                                           author: owner,
                                           parent: epics[:v10_launch]),
          web_app_user_settings: create(:epic,
                                        group: group,
                                        title: 'Web App User Settings',
                                        labels: [labels[:comp_settings], labels[:squad_b], labels[:type_3_feature]],
                                        author: owner,
                                        parent: epics[:v10_launch]),
          web_app_v10_interface: create(:epic,
                                        group: group,
                                        title: 'Web App v1.0 Interface',
                                        labels: [
                                          labels[:capability_4_in_progress],
                                          labels[:effort_m],
                                          labels[:type_2_capability]
                                        ],
                                        author: owner,
                                        parent: epics[:v10_launch]),
          create_account_flow: create(:epic,
                                      group: group,
                                      title: 'Create account flow',
                                      labels: [
                                        labels[:comp_auth],
                                        labels[:squad_b],
                                        labels[:type_3_feature]
                                      ],
                                      author: owner,
                                      parent: epics[:v10_launch]),
          mobile_create_account_flow: create(:epic,
                                             group: group,
                                             title: 'Mobile create account flow',
                                             labels: [labels[:squad_a], labels[:type_3_feature]],
                                             author: owner,
                                             parent: epics[:v10_launch])
        }

        create(:project, :public, name: 'Web App', namespace: group, creator: owner).tap do |project|
          create(:incident, project: project, title: 'Incident', description: 'Default MD')
          create(:issue, project: project, title: 'Do this...', description: '- [ ] markdown')
          green_issue = create(:issue, project: project, title: 'The button should be green', description: '- [ ] ...')
          create(:issue, project: project, title: 'Foo')
          create(:issue, project: project, title: 'Bar')

          create(:epic_issue,
                 epic: group_epics[:mobile_app_v10_interface],
                 issue: create(:issue,
                               project: project,
                               title: 'Discovery: User settings',
                               weight: 5,
                               milestone: milestones[:release_3],
                               labels: [labels[:type_4_story], labels[:wf_6_in_progress]],
                               health_status: :needs_attention).tap do |issue|
                          create(:timelog, issue: issue, time_spent: 8 * 60) # 8hrs
                        end)

          create(:epic_issue,
                 epic: group_epics[:create_account_flow],
                 issue: create(:issue,
                               project: project,
                               title: 'Redirect to home page on account creation success',
                               weight: 9,
                               milestone: milestones[:release_2],
                               labels: [labels[:comp_auth], labels[:priority_2], labels[:wf_5_ready]],
                               health_status: :at_risk).tap do |issue|
                          create(:timelog, issue: issue, time_spent: 60) # 1hr
                        end)

          create(:epic_issue,
                 epic: group_epics[:create_account_flow],
                 issue: create(:issue,
                               project: project,
                               title: 'error UX on failed account creation',
                               weight: 8,
                               health_status: :on_track,
                               labels: [
                                 labels[:type_4_task],
                                 labels[:wf_6_in_progress]
                               ],
                               milestone: milestones[:release_2],
                               description: <<~MARKDOWN))
                                 # To Do

                                 - [ ] Validate input
                                 - [ ] ##{green_issue.id}+
                               MARKDOWN

          create(:epic_issue,
                 epic: group_epics[:create_account_flow],
                 issue: create(:issue,
                               project: project,
                               title: 'Create account form',
                               description: 'Lorem ipsum dolor sit amet',
                               milestone: milestones[:release_2],
                               weight: 4,
                               labels: [labels[:type_4_task], labels[:wf_5_ready]]).tap do |issue|
                          create(:timelog, issue: issue, time_spent: 3 * 60) # 3hrs
                        end)
        end

        create(:project, :public, name: 'Mobile App', namespace: group, creator: owner).tap do |project|
          create(:epic_issue,
                 epic: group_epics[:mobile_app_v10_interface],
                 issue: create(:issue,
                               project: project,
                               title: 'Mobile app user settings discovery',
                               description: '- [x] Get manager authorization',
                               milestone: milestones[:release_4],
                               labels: [labels[:type_4_story], labels[:wf_3_validation]]))

          create(:epic_issue,
                 epic: group_epics[:web_app_user_settings],
                 issue: create(:issue,
                               project: project,
                               title: 'App initialization view',
                               description: 'Yessir',
                               milestone: milestones[:release_3],
                               labels: [labels[:type_4_task], labels[:wf_5_ready]]))

          create(:epic_issue,
                 epic: group_epics[:mobile_create_account_flow],
                 issue: create(:issue,
                               project: project,
                               title: 'Mobile create account form',
                               weight: 5,
                               milestone: milestones[:release_3],
                               labels: [labels[:type_4_task], labels[:wf_5_ready]],
                               health_status: :on_track,
                               description: <<~MARKDOWN))
                                 # Proposal

                                 - [x] Task

                                 # Diagrams
                               MARKDOWN
        end
      end
    end

    # Services
    def create_services
      create(:group, name: 'Services', parent: namespace).tap do |group|
        group_labels = {
          alliance: create(:group_label, group: group, title: 'Alliance', color: '#EEE600')
        }

        create(:project, :public, name: 'Labels', namespace: group, creator: owner)
        create(:project, :public, name: 'API', namespace: group, creator: owner).tap do |project|
          create(:issue, project: project, title: 'Alliance', description: '', labels: [group_labels[:alliance]])

          create(:issue, project: project, title: 'Level 7 Issue', milestone: milestones[:release_1], weight: 5)
          create(:issue, project: project, title: 'Bug template', labels: [labels[:type_4_bug], labels[:wf_4_refine]])
          create(:issue,
                 project: project,
                 title: 'API Bug',
                 labels: [labels[:type_4_bug], labels[:wf_7_review]],
                 weight: 5)

          create(:issue,
                 project: project,
                 title: 'Implement another endpoint',
                 labels: [labels[:priority_2], labels[:type_4_story], labels[:wf_6_in_progress]],
                 weight: 5)

          create(:issue,
                 project: project,
                 title: 'Implement new settings endpoint',
                 milestone: milestones[:release_2],
                 weight: 5, labels: [labels[:type_4_task], labels[:wf_7_review]], time_estimate: 3.hours.to_i)

          create(:issue,
                 project: project,
                 title: 'Fix a bug',
                 weight: 5,
                 labels: [labels[:type_4_bug], labels[:wf_5_ready]])

          create(:issue,
                 project: project,
                 title: 'Implement new server runbook',
                 milestone: milestones[:release_2],
                 time_estimate: 40.hours.to_i,
                 weight: 3,
                 labels: [labels[:type_4_task], labels[:wf_5_ready]])

          create(:issue,
                 project: project,
                 title: 'Add support for POST /settings',
                 milestone: milestones[:release_1],
                 weight: 4,
                 labels: [labels[:type_4_task]])

          create(:issue,
                 project: project,
                 title: 'Add support for GET /settings',
                 milestone: milestones[:release_2],
                 weight: 5,
                 labels: [labels[:type_4_task], labels[:wf_7_review]],
                 time_estimate: 1.hour.to_i)

          create(:issue,
                 project: project,
                 title: 'Add support for GET /user',
                 milestone: milestones[:release_1],
                 weight: 2,
                 labels: [labels[:type_4_task], labels[:wf_6_in_progress]])

          create(:issue,
                 project: project,
                 title: 'Add support for POST /user',
                 milestone: milestones[:release_4],
                 weight: 2,
                 labels: [labels[:type_4_task]])
        end

        create(:project, :public, name: 'Customer Portal', namespace: group, creator: owner)
      end
    end

    # Ideas
    def create_ideas
      create(:project, :public, name: 'Ideas', namespace: namespace, creator: owner)
    end

    # Ops
    def create_ops
      create(:project, :public, name: 'Ops', namespace: namespace, creator: owner).tap do |project|
        new_bug = create(:issue,
                         project: project,
                         title: 'New bug',
                         labels: [labels[:type_4_bug], labels[:wf_4_refine]],
                         description: <<~MARKDOWN)
                           # Current behavior
                           1.

                           # Steps to reproduce
                           1.

                           # Expected behavior
                           1.
                         MARKDOWN

        create(:issue, project: project, title: 'Task 1', description: <<~MARKDOWN)
          - #{new_bug.id}
          - #{new_bug.id}+
        MARKDOWN
      end
    end
  end
end
