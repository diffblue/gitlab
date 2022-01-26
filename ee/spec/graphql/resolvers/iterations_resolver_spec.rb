# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::IterationsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:current_user) { create(:user) }

    let(:params_list) do
      {
        id: nil,
        iid: nil,
        iteration_cadence_ids: nil,
        parent: nil,
        state: nil,
        search: nil,
        in: nil,
        sort: nil
      }
    end

    context 'for group iterations' do
      let_it_be(:now) { Time.now }
      let_it_be(:group) { create(:group, :private) }

      def resolve_group_iterations(args = {}, obj = group, context = { current_user: current_user })
        resolve(described_class, obj: obj, args: args, ctx: context)
      end

      before do
        group.add_developer(current_user)
      end

      it 'calls IterationsFinder#execute' do
        expect_next_instance_of(IterationsFinder) do |finder|
          expect(finder).to receive(:execute)
        end

        resolve_group_iterations
      end

      context 'without parameters' do
        it 'calls IterationsFinder to retrieve all iterations' do
          params = params_list.merge(parent: group, include_ancestors: true, state: 'all')

          expect(IterationsFinder).to receive(:new).with(current_user, params).and_call_original

          resolve_group_iterations
        end
      end

      context 'with parameters' do
        context 'search' do
          using RSpec::Parameterized::TableSyntax

          let_it_be(:plan_cadence) { create(:iterations_cadence, title: 'plan cadence', group: group) }
          let_it_be(:product_cadence) { create(:iterations_cadence, title: 'product management', group: group) }
          let_it_be(:plan_iteration1) { create(:iteration, :with_due_date, title: "Iteration 1", iterations_cadence: plan_cadence, start_date: 1.week.ago)}
          let_it_be(:plan_iteration2) { create(:iteration, :with_due_date, title: "My iteration", iterations_cadence: plan_cadence, start_date: 2.weeks.ago)}
          let_it_be(:product_iteration) { create(:iteration, :with_due_date, iterations_cadence: product_cadence, start_date: 1.week.from_now)}

          let(:all_iterations) { group.iterations }

          context 'with search and in parameters' do
            where(:search, :fields_to_search, :expected_iterations) do
              ''          | []                       | lazy { all_iterations }
              'iteration' | nil                      | lazy { plan_cadence.iterations }
              'iteration' | []                       | lazy { plan_cadence.iterations }
              'iteration' | [:title]                 | lazy { plan_cadence.iterations }
              'iteration' | [:title, :cadence_title] | lazy { plan_cadence.iterations }
              'plan'      | []                       | lazy { [] }
              'plan'      | [:cadence_title]         | lazy { plan_cadence.iterations }
            end

            with_them do
              it "returns correct items" do
                expect(resolve_group_iterations({ search: search, in: fields_to_search }).items).to contain_exactly(*expected_iterations)
              end
            end
          end

          context "with the deprecated argument 'title' (to be deprecated in 15.4)" do
            [
              { search: "foo" },
              { in: [:title] },
              { in: [:cadence_title] }
            ].each do |params|
              it "raises an error when 'title' is used with #{params}" do
                expect do
                  resolve_group_iterations({ title: "foo", **params })
                end.to raise_error(Gitlab::Graphql::Errors::ArgumentError, "'title' is deprecated in favor of 'search'. Please use 'search'.")
              end
            end

            it "raises an error when 'in' is specified but 'search' is not" do
              expect do
                resolve_group_iterations({ in: [:title] })
              end.to raise_error(Gitlab::Graphql::Errors::ArgumentError, "'search' must be specified when using 'in' argument.")
            end

            it "uses 'search' and 'in' arguments to search title" do
              expect(resolve_group_iterations({ title: 'iteration' }).items).to contain_exactly(*plan_cadence.iterations)
            end
          end
        end

        it 'calls IterationsFinder with correct parameters, using timeframe' do
          start_date = now
          end_date = start_date + 1.hour
          search = 'wow'
          id = '1'
          iid = 2
          iteration_cadence_ids = ['5']

          params = params_list.merge(id: id, iid: iid, iteration_cadence_ids: iteration_cadence_ids, parent: group, include_ancestors: nil, state: 'closed', start_date: start_date, end_date: end_date, search: search, in: [:title])

          expect(IterationsFinder).to receive(:new).with(current_user, params).and_call_original

          resolve_group_iterations(timeframe: { start: start_date, end: end_date }, state: 'closed', search: search, id: 'gid://gitlab/Iteration/1', iteration_cadence_ids: ['gid://gitlab/Iterations::Cadence/5'], iid: iid)
        end

        it 'calls IterationsFinder with correct parameters, using start and end date' do
          start_date = now
          end_date = start_date + 1.hour
          search = 'wow'
          id = '1'
          iid = 2
          iteration_cadence_ids = ['5']

          params = params_list.merge(id: id, iid: iid, iteration_cadence_ids: iteration_cadence_ids, parent: group, include_ancestors: nil, state: 'closed', start_date: start_date, end_date: end_date, search: search, in: [:title])

          expect(IterationsFinder).to receive(:new).with(current_user, params).and_call_original

          resolve_group_iterations(start_date: start_date, end_date: end_date, state: 'closed', search: search, id: 'gid://gitlab/Iteration/1', iteration_cadence_ids: ['gid://gitlab/Iterations::Cadence/5'], iid: iid)
        end

        it 'accepts a raw model id for backward compatibility' do
          id = 1
          iid = 2
          params = params_list.merge(id: id, iid: iid, parent: group, include_ancestors: nil, state: 'all')

          expect(IterationsFinder).to receive(:new).with(current_user, params).and_call_original

          resolve_group_iterations(id: id, iid: iid)
        end
      end

      context 'with subgroup' do
        let_it_be(:subgroup) { create(:group, :private, parent: group) }

        it 'defaults to include_ancestors' do
          params = params_list.merge(parent: subgroup, include_ancestors: true, state: 'all')

          expect(IterationsFinder).to receive(:new).with(current_user, params).and_call_original

          resolve_group_iterations({}, subgroup)
        end

        it 'does not default to include_ancestors if IID is supplied' do
          params = params_list.merge(iid: 1, parent: subgroup, include_ancestors: false, state: 'all')

          expect(IterationsFinder).to receive(:new).with(current_user, params).and_call_original

          resolve_group_iterations({ iid: 1, include_ancestors: false }, subgroup)
        end

        it 'accepts include_ancestors false' do
          params = params_list.merge(parent: subgroup, include_ancestors: false, state: 'all')

          expect(IterationsFinder).to receive(:new).with(current_user, params).and_call_original

          resolve_group_iterations({ include_ancestors: false }, subgroup)
        end
      end

      context 'by timeframe' do
        context 'when start_date and end_date are present' do
          context 'when start date is after end_date' do
            it 'raises error' do
              expect do
                resolve_group_iterations(timeframe: { start: now, end: now - 2.days })
              end.to raise_error(Gitlab::Graphql::Errors::ArgumentError, "start must be before end")
            end
          end
        end
      end

      context 'by dates' do
        context 'when start_date and end_date are present' do
          context 'when start date is after end_date' do
            it 'raises error' do
              expect do
                resolve_group_iterations(start_date: now, end_date: now - 2.days)
              end.to raise_error(Gitlab::Graphql::Errors::ArgumentError, "startDate is after endDate")
            end
          end
        end

        context 'when only start_date is present' do
          it 'raises error' do
            expect do
              resolve_group_iterations(start_date: now)
            end.to raise_error(Gitlab::Graphql::Errors::ArgumentError, /Both startDate and endDate/)
          end
        end

        context 'when only end_date is present' do
          it 'raises error' do
            expect do
              resolve_group_iterations(end_date: now)
            end.to raise_error(Gitlab::Graphql::Errors::ArgumentError, /Both startDate and endDate/)
          end
        end
      end

      context 'when user cannot read iterations' do
        it 'raises error' do
          unauthorized_user = create(:user)

          expect do
            resolve_group_iterations({}, group, { current_user: unauthorized_user })
          end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end
  end
end
