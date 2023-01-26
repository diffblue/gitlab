# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'epics hierarchy finder with filtering' do
  context 'with correct params' do
    before do
      group.add_developer(search_user) if search_user
    end

    it 'returns all epics even if user can not access them' do
      expect(epics).to eq(result_with_sort([epic3, epic2, epic1]))
    end

    context 'with created_at' do
      it 'returns all epics created before the given date' do
        expect(epics(created_before: 2.days.before(reference_time))).to eq(result_with_sort([epic2, epic1]))
      end

      it 'returns all epics created after the given date' do
        expect(epics(created_after: 2.days.before(reference_time))).to contain_exactly(epic3)
      end

      it 'returns all epics created within the given interval' do
        expect(epics(created_after: 5.days.before(reference_time), created_before: 1.day.before(reference_time)))
          .to contain_exactly(epic2)
      end
    end

    context 'with search' do
      it 'returns all epics that match the search' do
        expect(epics(search: 'awesome')).to eq(result_with_sort([epic3, epic1]))
      end
    end

    context 'with user reaction emoji' do
      it 'returns epics reacted to by user' do
        create(:award_emoji, name: 'thumbsup', awardable: epic1, user: search_user )
        create(:award_emoji, name: 'star', awardable: epic3, user: search_user )

        expect(epics(my_reaction_emoji: 'star')).to contain_exactly(epic3)
      end
    end

    context 'with author' do
      it 'returns all epics authored by the given user' do
        expect(epics(author_id: user.id)).to contain_exactly(epic2)
      end

      context 'when using OR' do
        it 'returns all epics authored by any of the given users' do
          expect(epics(or: { author_username: [epic2.author.username, epic3.author.username] }))
            .to eq(result_with_sort([epic3, epic2]))
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(or_issuable_queries: false)
          end

          it 'does not add any filter' do
            expect(epics(or: { author_username: [epic2.author.username, epic3.author.username] }))
              .to eq(result_with_sort([epic3, epic2, epic1]))
          end
        end
      end
    end

    context 'with label' do
      let(:finder_params) { { base_param.to_s => epic4 } }

      it 'returns all epics with given label' do
        expect(epics(finder_params.merge(label_name: label.title))).to contain_exactly(epic1)
      end

      it 'returns all epics without negated label' do
        expect(epics(finder_params.merge(not: { label_name: [label.title] })))
          .to eq(result_with_sort([epic3, epic2]))
      end
    end

    context 'with state' do
      it 'returns all epics with given state' do
        expect(epics(state: :closed)).to contain_exactly(epic3)
      end
    end

    context 'with timeframe' do
      it 'returns epics which start in the timeframe' do
        params = {
          start_date: 2.days.before(reference_time).strftime('%Y-%m-%d'),
          end_date: 1.day.before(reference_time).strftime('%Y-%m-%d')
        }

        expect(epics(params)).to contain_exactly(epic2)
      end

      it 'returns epics which end in the timeframe' do
        params = {
          start_date: 4.days.before(reference_time).strftime('%Y-%m-%d'),
          end_date: 3.days.before(reference_time).strftime('%Y-%m-%d')
        }

        expect(epics(params)).to contain_exactly(epic3)
      end

      it 'returns epics which start before and end after the timeframe' do
        params = {
          start_date: 4.days.before(reference_time).strftime('%Y-%m-%d'),
          end_date: 4.days.before(reference_time).strftime('%Y-%m-%d')
        }

        expect(epics(params)).to contain_exactly(epic3)
      end

      describe 'when one of the timeframe params are missing' do
        it 'does not filter by timeframe if start_date is missing' do
          only_end_date = epics(end_date: 1.year.before(reference_time).strftime('%Y-%m-%d'))

          expect(only_end_date).to eq(epics)
        end

        it 'does not filter by timeframe if end_date is missing' do
          only_start_date = epics(start_date: 1.year.since(reference_time).strftime('%Y-%m-%d'))

          expect(only_start_date).to eq(epics)
        end
      end
    end

    context 'with milestone' do
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:another_project) { create(:project, group: another_group) }
      let_it_be(:group_milestone) { create(:milestone, group: group, title: 'test') }
      let_it_be(:another_milestone) { create(:milestone, project: another_project, title: 'test') }
      let_it_be(:issue) { create(:issue, project: project, milestone: group_milestone) }
      let_it_be(:another_issue) { create(:issue, project: another_project, milestone: another_milestone) }
      let_it_be(:epic_issue) { create(:epic_issue, epic: epic2, issue: issue) }
      let_it_be(:another_epic_issue) { create(:epic_issue, epic: epic3, issue: another_issue) }

      it 'returns empty result if the milestone is not present' do
        params = { milestone_title: 'milestone title' }

        expect(epics(params)).to be_empty
      end

      it 'returns only epics which have an issue from the milestone' do
        params = { milestone_title: 'test' }

        expect(epics(params)).to eq(result_with_sort([epic3, epic2]))
      end
    end

    context 'when using iid starts with query' do
      it 'returns the expected epics if just the first two numbers are given' do
        params = { iid_starts_with: '98' }

        expect(epics(params)).to eq(result_with_sort([epic2, epic1]))
      end

      it 'returns the expected epics if the exact id is given' do
        params = { iid_starts_with: '9835' }

        expect(epics(params)).to contain_exactly(epic1)
      end

      it 'fails if iid_starts_with contains a non-numeric string' do
        expect { epics({ iid_starts_with: 'foo' }) }.to raise_error(ArgumentError)
      end

      it 'fails if iid_starts_with contains a non-numeric string with line breaks' do
        expect { epics({ iid_starts_with: "foo\n1" }) }.to raise_error(ArgumentError)
      end

      it 'fails if iid_starts_with contains a string which contains a negative number' do
        expect { epics(iid_starts_with: '-1') }.to raise_error(ArgumentError)
      end
    end
  end

  def result_with_sort(data = [])
    return data unless sort_order == :desc

    data.reverse
  end
end
