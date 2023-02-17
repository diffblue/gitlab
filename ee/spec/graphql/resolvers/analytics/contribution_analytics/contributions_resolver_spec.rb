# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Analytics::ContributionAnalytics::ContributionsResolver do
  include GraphqlHelpers

  def resolve_contributions(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: group, args: args, ctx: context, arg_style: :internal)
  end

  describe '#resolve' do
    let(:args) { { from: Date.parse('2022-04-25'), to: Date.parse('2022-05-10') } }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:user) { create(:user).tap { |u| group.add_developer(user) } }
    let(:current_user) { user }

    context 'without data' do
      it { expect(resolve_contributions(args)).to be_empty }
    end

    context 'with data' do
      let_it_be(:another_user) { create(:user).tap { |u| group.add_developer(user) } }

      let_it_be(:event1) do
        create(:event, :pushed, project: project, author: user, created_at: Date.parse('2022-04-27'))
      end

      let_it_be(:event2) do
        create(:event, :pushed, project: project, author: another_user, created_at: Date.parse('2022-05-01'))
      end

      let_it_be(:event3) do
        create(:event, :created, :for_issue, project: project, author: user, created_at: Date.parse('2022-05-05'))
      end

      it 'returns the aggregated event counts' do
        contributions = resolve_contributions(args)

        expect(contributions).to eq([
                                      {
                                        user: user,
                                        issues_closed: 0,
                                        issues_created: 1,
                                        merge_requests_approved: 0,
                                        merge_requests_closed: 0,
                                        merge_requests_created: 0,
                                        merge_requests_merged: 0,
                                        push: 1,
                                        total_events: 2
                                      },
                                      {
                                        user: another_user,
                                        issues_closed: 0,
                                        issues_created: 0,
                                        merge_requests_approved: 0,
                                        merge_requests_closed: 0,
                                        merge_requests_created: 0,
                                        merge_requests_merged: 0,
                                        push: 1,
                                        total_events: 1
                                      }
                                    ])
      end

      context 'when the date range is too wide' do
        let(:args) { { from: Date.parse('2021-01-01'), to: Date.parse('2022-05-10') } }

        it 'raises error' do
          error_message = s_('ContributionAnalytics|The given date range is larger than 93 days')

          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, error_message) do
            resolve_contributions(args)
          end
        end
      end

      context 'when `to` is earlier than `from`' do
        let(:args) { { to: Date.parse('2022-04-25'), from: Date.parse('2022-05-10') } }

        it 'raises error' do
          error_message = s_('ContributionAnalytics|The to date is earlier than the given from date')

          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, error_message) do
            resolve_contributions(args)
          end
        end
      end
    end
  end
end
