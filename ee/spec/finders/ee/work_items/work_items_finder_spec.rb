# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::WorkItemsFinder do
  context 'when filtering work items' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    subject do
      described_class.new(user, params).execute
    end

    context 'with status widget' do
      let_it_be(:work_item1) { create(:work_item, project: project) }
      let_it_be(:work_item2) { create(:work_item, :satisfied_status, project: project) }

      let(:params) { { status_widget: { status: 'passed' } } }

      before do
        project.add_reporter(user)
      end

      it 'returns correct results' do
        is_expected.to match_array([work_item2])
      end
    end

    context 'with legacy requirement widget' do
      let_it_be(:work_item1) { create(:work_item, project: project) }
      let_it_be(:work_item2) { create(:work_item, :satisfied_status, project: project) }

      let(:params) { { requirement_legacy_widget: { legacy_iids: work_item2.requirement.iid } } }

      before do
        project.add_reporter(user)
      end

      it 'returns correct results' do
        is_expected.to match_array([work_item2])
      end
    end
  end
end
