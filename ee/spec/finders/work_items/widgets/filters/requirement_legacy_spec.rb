# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Filters::RequirementLegacy, feature_category: :requirements_management do
  describe '.filter' do
    let_it_be(:project) { create(:project) }
    let_it_be(:work_item) { create(:work_item, :requirement, project: project, iid: 35) }
    let_it_be(:work_item1) { create(:work_item, :requirement, project: project, iid: 74) }
    let_it_be(:work_item2) { create(:work_item, :requirement, project: project, iid: 356) }
    let_it_be(:other_project_work_item) { create(:work_item, :requirement, project: create(:project), iid: 35) }

    let(:relation) { WorkItem.where(project: project) }
    let(:legacy_iids) { Array.wrap(expected_results).map(&:requirement).map(&:iid) }
    let(:filter) { { requirement_legacy_widget: { legacy_iids: legacy_iids } } }

    subject { described_class.filter(relation, filter) }

    context 'when legacy_iids parameter contains a single item' do
      let(:expected_results) { work_item }

      it { is_expected.to contain_exactly(expected_results) }
    end

    context 'when legacy_iids parameter contains multiple items' do
      let(:expected_results) { [work_item, work_item1, work_item2] }

      it { is_expected.to contain_exactly(*expected_results) }
    end

    context 'when legacy_iids parameter is nil' do
      let(:legacy_iids) { nil }

      it { is_expected.to contain_exactly(work_item, work_item1, work_item2) }
    end
  end
end
