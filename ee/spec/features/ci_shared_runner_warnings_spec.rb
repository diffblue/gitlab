# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CI shared runner limits', feature_category: :runner do
  using RSpec::Parameterized::TableSyntax
  include UsageQuotasHelpers

  let_it_be(:user) { create(:user) }

  let(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: true) }
  let(:group) { create(:group) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.sha, ref: 'master') }
  let!(:job) { create(:ci_build, pipeline: pipeline) }

  before do
    group.add_member(user, membership_level)
    sign_in(user)
  end

  where(:membership_level, :visible) do
    :owner | true
    :developer | false
  end

  with_them do
    context 'when on a project related page' do
      where(:membership_level, :visible) do
        :owner | true
        :developer | false
      end

      before do
        group.add_member(user, membership_level)
      end

      where(:case_name, :percent_threshold, :minutes_limit, :minutes_used) do
        'warning level' | 30 | 1000 | 800
        'danger level'  | 5  | 1000 | 980
      end

      with_them do
        context "when there is a notification and minutes still exist", :js do
          let(:message) do
            "#{group.name} namespace has #{percent_threshold}% or less Shared Runner Pipeline minutes remaining. " \
              "After it runs out, no new jobs or pipelines in its projects will run."
          end

          before do
            group.update!(shared_runners_minutes_limit: minutes_limit)
            allow_next_instance_of(::Ci::Minutes::Usage) do |instance|
              allow(instance).to receive(:total_minutes_used).and_return(minutes_used)
            end
          end

          it 'displays a warning message on pipelines page' do
            visit project_pipelines_path(project)

            alerts_according_to_role(visible: visible, message: message)
          end

          it 'displays a warning message on project homepage' do
            visit project_path(project)

            alerts_according_to_role(visible: visible, message: message)
          end

          it 'displays a warning message on a job page' do
            visit project_job_path(project, job)

            alerts_according_to_role(visible: visible, message: message)
          end
        end
      end

      context 'when limit is exceeded', :js do
        let(:group) { create(:group, :with_used_build_minutes_limit) }
        let(:message) do
          "#{group.name} namespace has exceeded its pipeline minutes quota. " \
            "Buy additional pipeline minutes, or no new jobs or pipelines in its projects will run."
        end

        it 'displays a warning message on project homepage' do
          visit project_path(project)

          alerts_according_to_role(visible: visible, message: message)
        end

        it 'displays a warning message on pipelines page' do
          visit project_pipelines_path(project)

          alerts_according_to_role(visible: visible, message: message)
        end

        it 'displays a warning message on a job page' do
          visit project_job_path(project, job)

          alerts_according_to_role(visible: visible, message: message)
        end

        context 'when in a subgroup', :saas do
          let(:subgroup) { create(:group, parent: group) }
          let(:subproject) { create(:project, :repository, namespace: subgroup, shared_runners_enabled: true) }
          let(:pipeline) { create(:ci_empty_pipeline, project: subproject, sha: subproject.commit.sha, ref: 'master') }
          let!(:job) { create(:ci_build, pipeline: pipeline) }

          it 'displays a warning message on subproject homepage' do
            visit project_path(subproject)

            alerts_according_to_role(visible: visible, message: message)
          end
        end
      end

      context 'when limit not yet exceeded' do
        let(:group) { create(:group, :with_not_used_build_minutes_limit) }

        it 'does not display a warning message on project homepage' do
          visit project_path(project)

          expect_no_quota_exceeded_alert
        end

        it 'does not display a warning message on pipelines page' do
          visit project_pipelines_path(project)

          expect_no_quota_exceeded_alert
        end

        it 'displays a warning message on a job page' do
          visit project_job_path(project, job)

          expect_no_quota_exceeded_alert
        end
      end
    end

    context 'when on a group related page' do
      where(:case_name, :percent_threshold, :minutes_limit, :minutes_used) do
        'warning level' | 30 | 1000 | 800
        'danger level'  | 5  | 1000 | 980
      end

      with_them do
        context "when there is a notification and minutes still exist", :js do
          let(:message) do
            "#{group.name} namespace has #{percent_threshold}% or less Shared Runner Pipeline minutes remaining. " \
              "After it runs out, no new jobs or pipelines in its projects will run."
          end

          before do
            group.update!(shared_runners_minutes_limit: minutes_limit)
            allow_next_instance_of(::Ci::Minutes::Usage) do |instance|
              allow(instance).to receive(:total_minutes_used).and_return(minutes_used)
            end
          end

          it 'displays a warning message on group information page' do
            visit group_path(group)

            alerts_according_to_role(visible: visible, message: message)
          end
        end
      end

      context 'when limit is exceeded', :js do
        let(:group) { create(:group, :with_used_build_minutes_limit) }
        let(:message) do
          "#{group.name} namespace has exceeded its pipeline minutes quota. " \
            "Buy additional pipeline minutes, or no new jobs or pipelines in its projects will run."
        end

        it 'displays a warning message on group information page' do
          visit group_path(group)

          alerts_according_to_role(visible: visible, message: message)
        end
      end

      context 'when limit not yet exceeded' do
        let(:group) { create(:group, :with_not_used_build_minutes_limit) }

        it 'does not display a warning message on group information page' do
          visit group_path(group)

          expect_no_quota_exceeded_alert
        end
      end
    end
  end

  def alerts_according_to_role(visible: false, message: '')
    visible ? expect_quota_exceeded_alert(message) : expect_no_quota_exceeded_alert
  end

  def expect_quota_exceeded_alert(message)
    expect(page).to have_selector('.shared-runner-quota-message', count: 1)

    page.within('.shared-runner-quota-message') do
      expect(page).to have_content(message)
      expect(page).to have_link 'Buy more Pipeline minutes', href: buy_minutes_subscriptions_link(group)
    end
  end

  def expect_no_quota_exceeded_alert
    expect(page).not_to have_selector('.shared-runner-quota-message')
  end
end
