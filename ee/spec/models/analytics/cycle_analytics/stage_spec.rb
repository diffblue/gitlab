# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::Stage, feature_category: :value_stream_management do
  include_examples 'value stream analytics label based stage' do
    let_it_be(:parent) { create(:group) }
    let_it_be(:parent_in_subgroup) { create(:group, parent: parent) }
    let_it_be(:group_label) { create(:group_label, group: parent) }
    let_it_be(:parent_outside_of_group_label_scope) { create(:group) }
  end

  context 'when Namespaces::ProjectNamespace record is given as namespace' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group).reload }

    let_it_be(:project_label) { create(:label, project: project) }
    let_it_be(:group_label) { create(:group_label, group: group) }

    let(:params) do
      {
        name: 'My Stage',
        namespace: project.project_namespace,
        start_event_identifier: :issue_label_added,
        start_event_label_id: group_label.id,
        end_event_identifier: :issue_closed
      }
    end

    subject(:stage) { described_class.new(params) }

    it 'is valid' do
      expect(stage).to be_valid
    end

    context 'when project label is given' do
      it 'is valid' do
        params[:start_event_label_id] = project_label.id

        expect(stage).to be_valid
      end
    end
  end
end
