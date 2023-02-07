# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::IterationService::CreateService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:iteration) { create(:iteration, iterations_cadence: cadence) }
  let_it_be_with_reload(:work_item) { create(:work_item, :issue, project: project, author: user) }

  let(:widget) { work_item.widgets.find { |widget| widget.is_a?(WorkItems::Widgets::Iteration) } }

  describe '#before_create_callback' do
    subject { described_class.new(widget: widget, current_user: user).before_create_callback(params: params) }

    it_behaves_like 'iteration change is handled'
  end
end
