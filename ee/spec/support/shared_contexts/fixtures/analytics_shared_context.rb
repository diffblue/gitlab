# frozen_string_literal: true

RSpec.shared_context '[EE] Analytics fixtures shared context' do
  include_context 'Analytics fixtures shared context'

  let_it_be(:value_stream) { create(:cycle_analytics_value_stream, namespace: group) }

  let(:label) { create(:group_label, name: 'in-code-review', group: group) }
  let(:label_based_stage) do
    create(:cycle_analytics_stage, {
      name: 'label-based-stage',
      namespace: group,
      value_stream: value_stream,
      start_event_identifier: :issue_label_added,
      start_event_label_id: label.id,
      end_event_identifier: :issue_label_removed,
      end_event_label_id: label.id
    })
  end

  let(:params) { { created_after: 3.months.ago, created_before: Time.now, group_id: group.full_path } }

  def additional_cycle_analytics_metrics
    create(:cycle_analytics_stage, namespace: group, value_stream: value_stream)

    update_metrics

    deploy_master(user, project, environment: 'staging')
  end

  def create_label_based_cycle_analytics_stage
    label_based_stage

    issue = create(:issue, project: project, created_at: 20.days.ago, author: user)

    travel_back
    travel_to(5.days.ago) do
      Issues::UpdateService.new(
        container: project,
        current_user: user,
        params: { label_ids: [label.id] }
      ).execute(issue)
    end

    travel_to(2.days.ago) do
      Issues::UpdateService.new(
        container: project,
        current_user: user,
        params: { label_ids: [] }
      ).execute(issue)
    end
  end

  before do
    # Persist the default stages
    Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map do |params|
      group.cycle_analytics_stages.build(params.merge(value_stream: value_stream)).save!
    end

    create_label_based_cycle_analytics_stage

    create_deployment

    additional_cycle_analytics_metrics

    sign_in(user)
  end
end
