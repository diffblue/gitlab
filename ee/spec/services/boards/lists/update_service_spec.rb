# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EE::Boards::Lists::UpdateService' do
  let(:group) { create(:group) }
  let(:user) { create(:group_member, :owner, group: group, user: create(:user)).user }
  let(:unpriviledged_user) { create(:group_member, :guest, group: group, user: create(:user)).user }

  shared_examples 'board list update' do
    context 'with licensed wip limits' do
      context 'limit metric' do
        it 'updates the list if limit_metric "issue_count" is given' do
          update_list_and_test_result(list, { limit_metric: 'issue_count' }, { limit_metric: 'issue_count' })
        end

        it 'updates the list if limit_metric "issue_weights" is given' do
          update_list_and_test_result(list, { limit_metric: 'issue_weights' }, { limit_metric: 'issue_weights' })
        end

        it 'updates the list if "all_metrics" limit_metric is given' do
          update_list_and_test_result(list, { limit_metric: 'all_metrics' }, { limit_metric: 'all_metrics' })
        end

        it 'updates the list if "all_metrics" limit_metric is given' do
          update_list_and_test_result(list, { limit_metric: '' }, { limit_metric: '' })
        end

        it 'updates the list if no limit_metric is given' do
          list.update!(limit_metric: 'issue_count')

          update_list_and_test_result(list, { limit_metric: nil }, { limit_metric: nil })
        end

        it 'fails if an invalid limit_metric is given' do
          service = Boards::Lists::UpdateService.new(board, user, { limit_metric: 'foo' })
          result = service.execute(list)

          expect(result.http_status).to eq(:unprocessable_entity)
          expect(result.status).to eq(:error)

          reloaded_list = list.reload
          expect(reloaded_list.limit_metric).to be_nil
        end
      end

      it 'updates the list if max_issue_count is given' do
        update_list_and_test_result(list, { max_issue_count: 42 }, { max_issue_count: 42 })
      end

      it 'updates the list if max_issue_weight is given' do
        update_list_and_test_result(list, { max_issue_weight: 42 }, { max_issue_weight: 42 })
      end

      it 'does not update the list if max_issue_weight is nil' do
        update_list_and_test_result(
          list,
          { max_issue_weight: nil },
          { max_issue_weight: 0 },
          expected_service_result: :error
        )
      end

      it 'updates the max issue count of the list if both count and weight limits are provided' do
        update_list_and_test_result(
          list,
          { max_issue_count: 10, max_issue_weight: 42 },
          { max_issue_count: 10, max_issue_weight: 42 }
        )
      end

      it 'does not change count if weight is updated' do
        list.update!(max_issue_count: 55)

        update_list_and_test_result(
          list,
          { max_issue_weight: 42 },
          { max_issue_count: 55, max_issue_weight: 42 }
        )
      end

      it 'does not change weight if count is updated' do
        list.update!(max_issue_weight: 55)

        update_list_and_test_result(
          list,
          { max_issue_count: 42 },
          { max_issue_weight: 55, max_issue_count: 42 }
        )
      end

      it 'does not update max_issue_count if max_issue_count is nil' do
        update_list_and_test_result(
          list,
          { max_issue_count: nil },
          { max_issue_count: 0 },
          expected_service_result: :error
        )
      end

      it 'sets max_issue_count to 0 if requested' do
        list.update!(max_issue_count: 3)

        update_list_and_test_result(list, { max_issue_count: 0 }, { max_issue_count: 0 })
      end

      it 'sets max_issue_weight to 0 if requested' do
        list.update!(max_issue_weight: 3)

        update_list_and_test_result(list, { max_issue_weight: 0 }, { max_issue_weight: 0 })
      end

      it 'sets max_issue_count to 0 if requested' do
        list.update!(max_issue_count: 10)

        update_list_and_test_result(
          list,
          { max_issue_count: 0, max_issue_weight: 0 },
          { max_issue_count: 0, max_issue_weight: 0 }
        )
      end

      it 'sets max_issue_weight to 0 if requested' do
        list.update!(max_issue_weight: 10)

        update_list_and_test_result(
          list,
          { max_issue_count: 0, max_issue_weight: 0 },
          { max_issue_count: 0, max_issue_weight: 0 }
        )
      end

      it 'does not update count and weight when negative values for both are given' do
        list.update!(max_issue_count: 10)

        update_list_and_test_result(
          list,
          { max_issue_count: -1, max_issue_weight: -1 },
          { max_issue_count: 10, max_issue_weight: 0 },
          expected_service_result: :error
        )
      end

      it 'sets count and weight to 0 when non numerical values are given' do
        list.update!(max_issue_count: 0, max_issue_weight: 3)

        update_list_and_test_result(
          list,
          { max_issue_count: 'test', max_issue_weight: 'test2' },
          { max_issue_count: 0, max_issue_weight: 0 }
        )
      end

      it 'does not update the list max issue count if can_admin returns false' do
        update_list_and_test_result_by_user(
          unpriviledged_user,
          list,
          { max_issue_count: 42 },
          { max_issue_count: 0 },
          expected_service_result: :error
        )
      end

      it 'does not update the list max issue weight if can_admin returns false' do
        update_list_and_test_result_by_user(
          unpriviledged_user,
          list,
          { max_issue_weight: 42 },
          { max_issue_weight: 0 },
          expected_service_result: :error
        )
      end
    end

    context 'without licensed wip limits' do
      before do
        stub_licensed_features(wip_limits: false)
      end

      it 'does not update the list even if max_issue_count is given' do
        update_list_and_test_result(
          list,
          { max_issue_count: 42 },
          { max_issue_count: 0 },
          expected_service_result: :error
        )
      end

      it 'does not update the list if can_admin returns false' do
        update_list_and_test_result_by_user(
          unpriviledged_user,
          list,
          { max_issue_count: 42 },
          { max_issue_count: 0 },
          expected_service_result: :error
        )
      end

      it 'does not update the list even if max_issue_weight is given' do
        update_list_and_test_result(
          list,
          { max_issue_weight: 42 },
          { max_issue_weight: 0 },
          expected_service_result: :error
        )
      end

      it 'does not update the list if can_admin returns false' do
        update_list_and_test_result_by_user(
          unpriviledged_user,
          list,
          { max_issue_weight: 42 },
          { max_issue_weight: 0 },
          expected_service_result: :error
        )
      end
    end

    def update_list_and_test_result(list, initialization_params, expected_list_attributes, expected_service_result: :success)
      update_list_and_test_result_by_user(
        user,
        list,
        initialization_params,
        expected_list_attributes,
        expected_service_result: expected_service_result
      )
    end

    def update_list_and_test_result_by_user(user, list, initialization_params, expected_list_attributes, expected_service_result: :success)
      service = Boards::Lists::UpdateService.new(board, user, initialization_params)
      result = service.execute(list)

      expect(result.status).to eq(expected_service_result)

      reloaded_list = list.reload

      expect(reloaded_list.max_issue_count).to eq(expected_list_attributes.fetch(:max_issue_count, 0))
      expect(reloaded_list.max_issue_weight).to eq(expected_list_attributes.fetch(:max_issue_weight, 0))
      expect(reloaded_list.limit_metric).to eq(expected_list_attributes[:limit_metric])
    end
  end

  context 'with project' do
    let(:project_board) { create(:board, project: project) }
    let(:project) { create(:project, group: group) }
    let(:project_board_list) { create(:list, board: project_board) }
    let(:board) { project_board }
    let(:list) { project_board_list }

    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'board list update'
  end

  context 'with group' do
    let(:group) { create(:group) }
    let(:group_board) { create(:board, group: group) }
    let(:group_board_list) { create(:list, board: group_board) }
    let(:board) { group_board }
    let(:list) { group_board_list }

    before do
      group.add_owner(user)
    end

    it_behaves_like 'board list update'
  end
end
