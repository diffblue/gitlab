# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::CrossHierarchyAncestorsFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:search_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:another_group) { create(:group, :private) }
  let_it_be(:reference_time) { Time.parse('2020-09-15 01:00') } # Arbitrary time used for time/date range filters
  let_it_be(:label) { create(:group_label, group: group) }

  let_it_be(:epic1) do
    create(
      :epic, :opened, group: another_group, title: 'This is awesome epic',
      created_at: 1.week.before(reference_time),
      end_date: 10.days.before(reference_time), labels: [label],
      iid: 9835
    )
  end

  let_it_be(:epic2, reload: true) do
    create(
      :epic, :opened, parent: epic1, group: group, created_at: 4.days.before(reference_time),
      author: user, start_date: 2.days.before(reference_time),
      end_date: 3.days.since(reference_time), iid: 9834
    )
  end

  let_it_be(:epic3, reload: true) do
    create(
      :epic, :closed, parent: epic2, group: another_group, description: 'not so awesome',
      start_date: 5.days.before(reference_time),
      end_date: 3.days.before(reference_time), iid: 6873
    )
  end

  let_it_be(:epic4) do
    create(
      :epic, parent: epic3, group: group, start_date: 6.days.before(reference_time),
      end_date: 6.days.before(reference_time), iid: 8876
    )
  end

  it_behaves_like 'epic findable finder'

  describe '#execute' do
    def epics(params = {})
      params[:child] ||= epic4

      described_class.new(search_user, params).execute
    end

    context 'when epics feature is disabled' do
      before do
        group.add_developer(search_user)
      end

      it 'raises an exception' do
        expect { described_class.new(search_user).execute }.to raise_error { ArgumentError }
      end
    end

    # Enabling the `request_store` for this to avoid counting queries that check
    # the license.
    context 'when epics feature is enabled', :request_store do
      before do
        stub_licensed_features(epics: true)
      end

      context 'without param' do
        it 'raises an error when child param is missing' do
          expect { described_class.new(search_user).execute }.to raise_error { ArgumentError }
        end
      end

      context 'when user can not read the epic' do
        it 'returns empty collection' do
          expect(epics).to be_empty
        end
      end

      context 'when user can read the epic' do
        before do
          group.add_developer(search_user)
        end

        context 'with parent' do
          it 'returns ancestor epics with given parent' do
            params = { child: epic4, parent_id: epic1.id }

            expect(epics(params)).to contain_exactly(epic2)
          end
        end

        it 'returns only accessible ancestors' do
          params = { child: epic4 }

          expect(epics(params)).to eq([epic2])
        end

        context 'with confidential epics' do
          let_it_be(:parent_epic) { create(:epic, :confidential, group: another_group) }
          let_it_be(:child_epic) { create(:epic, :confidential, group: group, parent: parent_epic) }

          context 'when user is guest in other group' do
            before do
              another_group.add_guest(search_user)
            end

            it 'filters out confidential parent' do
              params = { child: child_epic }

              expect(epics(params)).to be_empty
            end
          end

          context 'when user is reporter in other group' do
            before do
              another_group.add_reporter(search_user)
            end

            it 'returns confidential ancestor' do
              params = { child: child_epic }

              expect(epics(params)).to eq([parent_epic])
            end
          end
        end

        context 'when user can access all ancestors' do
          before do
            another_group.add_developer(search_user)
          end

          it 'returns an empty list if there is no parent' do
            params = { child: epic1 }

            expect(epics(params)).to be_empty
          end

          it 'returns ancestors in ascending order' do
            params = { child: epic4 }

            expect(epics(params)).to eq([epic3, epic2, epic1])
          end

          it_behaves_like 'epics hierarchy finder with filtering' do
            let(:base_param) { :child }
            let(:sort_order) { :asc }

            let_it_be(:public_group) { create(:group, :public) }
            let_it_be(:epic5) { create(:epic, group: public_group, title: 'tanuki') }
            let_it_be(:epic6) { create(:epic, parent: epic5, group: public_group, title: 'ikunat') }
            let_it_be(:epic7) { create(:epic, parent: epic6, group: public_group) }
          end
        end
      end
    end
  end
end
