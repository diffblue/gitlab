# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::CreateService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be_with_refind(:project) { create(:project, group: group) }
    let_it_be(:board, refind: true) { create(:board, project: project) }
    let_it_be(:user) { create(:user) }

    context 'when assignee_id param is sent' do
      let_it_be(:other_user) { create(:user) }

      before_all do
        project.add_developer(user)
        project.add_developer(other_user)
      end

      subject(:service) { described_class.new(project, user, 'assignee_id' => other_user.id) }

      before do
        stub_licensed_features(board_assignee_lists: true)
      end

      it 'creates a new assignee list' do
        response = service.execute(board)

        expect(response.success?).to eq(true)
        expect(response.payload[:list].list_type).to eq('assignee')
      end
    end

    context 'when milestone_id param is sent' do
      let_it_be(:milestone) { create(:milestone, project: project) }

      before_all do
        project.add_developer(user)
      end

      subject(:service) { described_class.new(project, user, 'milestone_id' => milestone.id) }

      before do
        stub_licensed_features(board_milestone_lists: true)
      end

      it 'creates a milestone list when param is valid' do
        response = service.execute(board)

        expect(response.success?).to eq(true)
        expect(response.payload[:list].list_type).to eq('milestone')
      end
    end

    context 'when iteration_id param is sent' do
      let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group)) }

      before_all do
        group.add_developer(user)
      end

      subject(:service) { described_class.new(project, user, 'iteration_id' => iteration.id) }

      before do
        stub_licensed_features(board_iteration_lists: true)
      end

      it 'creates an iteration list when param is valid' do
        response = service.execute(board)

        expect(response.success?).to eq(true)
        expect(response.payload[:list].list_type).to eq('iteration')
      end

      context 'when iteration is from another group' do
        let_it_be(:iteration) { create(:iteration) }

        it 'returns an error' do
          response = service.execute(board)

          expect(response.success?).to eq(false)
          expect(response.errors).to include('Iteration not found')
        end
      end

      it 'returns an error when license is unavailable' do
        stub_licensed_features(board_iteration_lists: false)

        response = service.execute(board)

        expect(response.success?).to eq(false)
        expect(response.errors).to include('Iteration lists not available with your current license')
      end
    end

    context 'max limits' do
      describe '#create_list_attributes' do
        shared_examples 'attribute provider for list creation' do
          before do
            stub_licensed_features(wip_limits: wip_limits_enabled)
          end

          where(:params, :expected_max_issue_count, :expected_max_issue_weight, :expected_limit_metric) do
            [
              [{ max_issue_count: 0 }, 0, 0, nil],
              [{ max_issue_count: nil }, 0, 0, nil],
              [{ max_issue_count: 1 }, 1, 0, nil],

              [{ max_issue_weight: 0 }, 0, 0, nil],
              [{ max_issue_weight: nil }, 0, 0, nil],
              [{ max_issue_weight: 1 }, 0, 1, nil],

              [{ max_issue_count: 1, max_issue_weight: 0 }, 1, 0, nil],
              [{ max_issue_count: 0, max_issue_weight: 1 }, 0, 1, nil],
              [{ max_issue_count: 1, max_issue_weight: 1 }, 1, 1, nil],

              [{ max_issue_count: nil, max_issue_weight: 1 }, 0, 1, nil],
              [{ max_issue_count: 1, max_issue_weight: nil }, 1, 0, nil],

              [{ max_issue_count: nil, max_issue_weight: nil }, 0, 0, nil],

              [{ limit_metric: 'all_metrics' }, 0, 0, 'all_metrics'],
              [{ limit_metric: 'issue_count' }, 0, 0, 'issue_count'],
              [{ limit_metric: 'issue_weights' }, 0, 0, 'issue_weights'],
              [{ limit_metric: '' }, 0, 0, ''],
              [{ limit_metric: nil }, 0, 0, nil]
            ]
          end

          with_them do
            it 'contains the expected max limits' do
              service = described_class.new(project, user, params)

              attrs = service.send(:create_list_attributes, nil, nil, nil)

              if wip_limits_enabled
                expect(attrs).to include(max_issue_count: expected_max_issue_count,
                                         max_issue_weight: expected_max_issue_weight,
                                         limit_metric: expected_limit_metric)
              else
                expect(attrs).not_to include(max_issue_count: 0, max_issue_weight: 0, limit_metric: nil)
              end
            end
          end
        end

        it_behaves_like 'attribute provider for list creation' do
          let(:wip_limits_enabled) { true }
        end

        it_behaves_like 'attribute provider for list creation' do
          let(:wip_limits_enabled) { false }
        end
      end
    end
  end
end
