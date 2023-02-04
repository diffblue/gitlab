# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItemsResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  before_all do
    project.add_reporter(user)
  end

  describe '#resolve', :aggregate_failures do
    let_it_be(:work_item1) { create(:work_item, :satisfied_status, project: project) }
    let_it_be(:work_item2) { create(:work_item, :failed_status, project: project) }
    let_it_be(:work_item3) { create(:work_item, :requirement, project: project) }

    context 'with status widget arguments', feature_category: :requirements_management do
      it 'filters work items by status' do
        expect(resolve_items(status_widget: { status: 'passed' })).to contain_exactly(work_item1)
        expect(resolve_items(status_widget: { status: 'failed' })).to contain_exactly(work_item2)
        expect(resolve_items(status_widget: { status: 'missing' })).to contain_exactly(work_item3)
      end

      context 'when work_items_mvc_2 flag is disabled' do
        before do
          stub_feature_flags(work_items_mvc_2: false)
        end

        it 'ignores status_widget argument' do
          expect(resolve_items(status_widget: { status: 'passed' }))
            .to contain_exactly(work_item1, work_item2, work_item3)
        end
      end
    end

    context 'with legacy requirement widget arguments', feature_category: :requirements_management do
      let_it_be(:work_item_from_other_project) do
        create(:work_item, :requirement, project: create(:project), iid: work_item1.iid)
      end

      it 'filters work items by legacy iid' do
        expect(resolve_items(
          requirement_legacy_widget: { legacy_iids: [work_item1.requirement.iid.to_s] }
        )).to contain_exactly(work_item1)

        expect(resolve_items(
          requirement_legacy_widget: { legacy_iids: [work_item1.requirement.iid.to_s, work_item2.requirement.iid.to_s] }
        )).to contain_exactly(work_item1, work_item2)

        expect(resolve_items(
          requirement_legacy_widget: { legacy_iids: ['nonsense'] }
        )).to be_empty
      end
    end
  end

  def resolve_items(args = {}, context = { current_user: user })
    resolve(described_class, obj: project, args: args, ctx: context, arg_style: :internal)
  end
end
