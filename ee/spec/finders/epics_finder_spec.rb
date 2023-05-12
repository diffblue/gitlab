# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicsFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:search_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:another_group) { create(:group) }
  let_it_be(:reference_time) { Time.parse('2020-09-15 01:00') } # Arbitrary time used for time/date range filters
  let_it_be(:epic1) { create(:epic, :opened, group: group, title: 'This is awesome epic', created_at: 1.week.before(reference_time), end_date: 10.days.before(reference_time)) }
  let_it_be(:epic3, reload: true) { create(:epic, :closed, group: group, description: 'not so awesome', start_date: 5.days.before(reference_time), end_date: 3.days.before(reference_time)) }
  let_it_be(:epic2, reload: true) { create(:epic, :opened, group: group, created_at: 4.days.before(reference_time), author: user, start_date: 2.days.before(reference_time), end_date: 3.days.since(reference_time)) }
  let_it_be(:epic5) { create(:epic, group: group, start_date: 6.days.before(reference_time), end_date: 6.days.before(reference_time), parent: epic3) }
  let_it_be(:epic4) { create(:epic, :closed, group: another_group) }

  describe '#execute' do
    def epics(params = {})
      params[:group_id] ||= group.id

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
        it 'raises an error when group_id param is missing' do
          expect { described_class.new(search_user).execute }.to raise_error { ArgumentError }
        end
      end

      context 'when user can not read epics of a group' do
        it 'returns empty collection' do
          expect(epics).to be_empty
        end
      end

      context 'with correct params' do
        before do
          group.add_developer(search_user) if search_user
        end

        it 'returns all epics that belong to the given group' do
          expect(epics).to contain_exactly(epic1, epic2, epic3, epic5)
        end

        it 'does not execute more than 5 SQL queries' do
          expect { epics.to_a }.not_to exceed_all_query_limit(5)
        end

        context 'sorting' do
          it 'sorts correctly when supported sorting param provided' do
            expect(epics(sort: :start_date_asc)).to eq([epic5, epic3, epic2, epic1])
          end

          it 'sorts by id when not supported sorting param provided' do
            expect(epics(sort: :not_supported_param)).to eq([epic5, epic2, epic3, epic1])
          end
        end

        context 'by created_at' do
          it 'returns all epics created before the given date' do
            expect(epics(created_before: 2.days.before(reference_time))).to contain_exactly(epic1, epic2)
          end

          it 'returns all epics created after the given date' do
            expect(epics(created_after: 2.days.before(reference_time))).to contain_exactly(epic3, epic5)
          end

          it 'returns all epics created within the given interval' do
            expect(epics(created_after: 5.days.before(reference_time), created_before: 1.day.before(reference_time))).to contain_exactly(epic2)
          end
        end

        context 'by search' do
          it 'returns all epics that match the search' do
            expect(epics(search: 'awesome')).to contain_exactly(epic1, epic3)
          end
        end

        context 'by user reaction emoji' do
          it 'returns epics reacted to by user' do
            create(:award_emoji, name: 'thumbsup', awardable: epic1, user: search_user )
            create(:award_emoji, name: 'star', awardable: epic3, user: search_user )

            expect(epics(my_reaction_emoji: 'star')).to contain_exactly(epic3)
          end
        end

        context 'by author' do
          it 'returns all epics authored by the given user' do
            expect(epics(author_id: user.id)).to contain_exactly(epic2)
          end

          context 'using OR' do
            it 'returns all epics authored by any of the given users' do
              expect(epics(or: { author_username: [epic2.author.username, epic3.author.username] })).to contain_exactly(epic2, epic3)
            end

            context 'when feature flag is disabled' do
              before do
                stub_feature_flags(or_issuable_queries: false)
              end

              it 'does not add any filter' do
                expect(epics(or: { author_username: [epic2.author.username, epic3.author.username] })).to contain_exactly(epic1, epic2, epic3, epic5)
              end
            end
          end
        end

        context 'by label' do
          let_it_be(:label) { create(:group_label, group: group) }
          let_it_be(:labeled_epic) { create(:labeled_epic, group: group, labels: [label]) }

          it 'returns all epics with given label' do
            expect(epics(label_name: label.title)).to contain_exactly(labeled_epic)
          end

          context 'with scoped label wildcard' do
            let_it_be(:scoped_label_1) { create(:group_label, group: group, title: 'devops::plan') }
            let_it_be(:scoped_label_2) { create(:group_label, group: group, title: 'devops::create') }

            let_it_be(:scoped_labeled_epic_1) { create(:labeled_epic, group: group, labels: [scoped_label_1]) }
            let_it_be(:scoped_labeled_epic_2) { create(:labeled_epic, group: group, labels: [scoped_label_2]) }

            before do
              stub_licensed_features(epics: true, scoped_labels: true)
            end

            it 'returns all epics that match the wildcard' do
              expect(epics(label_name: 'devops::*')).to contain_exactly(scoped_labeled_epic_1, scoped_labeled_epic_2)
            end
          end
        end

        context 'by state' do
          it 'returns all epics with given state' do
            expect(epics(state: :closed)).to contain_exactly(epic3)
          end
        end

        context 'when subgroups are supported' do
          let_it_be(:subgroup) { create(:group, :private, parent: group) }
          let_it_be(:subgroup_guest) { create(:user) }
          let_it_be(:subgroup2) { create(:group, :private, parent: subgroup) }
          let_it_be(:subgroup_epic) { create(:epic, group: subgroup) }
          let_it_be(:subgroup2_epic) { create(:epic, group: subgroup2) }
          let_it_be(:confidential_epic) { create(:epic, :confidential, group: subgroup2) }

          before do
            subgroup.add_guest(subgroup_guest)
          end

          it 'returns all epics that belong to the given group and its subgroups' do
            expect(epics)
              .to contain_exactly(epic1, epic2, epic3, subgroup_epic, subgroup2_epic, epic5, confidential_epic)
          end

          it 'does not return confidential epic if user has no permissions to read them' do
            expect(described_class.new(subgroup_guest, { group_id: subgroup.id }).execute)
              .to contain_exactly(subgroup_epic, subgroup2_epic)
          end

          describe 'hierarchy params' do
            let(:finder_params) { {} }

            subject { epics(finder_params.merge(group_id: subgroup.id)) }

            it 'excludes ancestor groups and includes descendant groups by default' do
              is_expected.to contain_exactly(subgroup_epic, subgroup2_epic, confidential_epic)
            end

            context 'when user is a member of a subgroup project' do
              let_it_be(:subgroup3) { create(:group, :private, parent: group) }
              let_it_be(:subgroup3_epic) { create(:epic, group: subgroup3) }
              let_it_be(:subgroup3_project) { create(:project, group: subgroup3) }
              let_it_be(:project_member) { create(:user) }

              let(:finder) { described_class.new(project_member, finder_params) }
              let(:finder_params) { { include_descendant_groups: true, include_ancestor_groups: true, group_id: group.id } }

              before do
                subgroup3_project.add_reporter(project_member)
              end

              subject { finder.execute }

              it 'gets only epics from the project ancestor groups' do
                is_expected.to contain_exactly(epic1, epic2, epic3, subgroup3_epic, epic5)
              end
            end

            context 'when user is a member of an ancestor group that is not the root ancestor' do
              let_it_be(:subgroup_reporter) { create(:user) }

              let(:finder) { described_class.new(subgroup_reporter, finder_params) }
              let(:finder_params) { { include_descendant_groups: false, group_id: subgroup2.id } }

              before do
                subgroup.add_reporter(subgroup_reporter)
              end

              context 'when include_ancestor_groups is false' do
                it 'includes subgroups confidential epics and no epics from ancestors' do
                  finder_params[:include_ancestor_groups] = false

                  expect(finder.execute).to contain_exactly(subgroup2_epic, confidential_epic)
                end
              end

              context 'when include_ancestor_groups is true' do
                it 'includes subgroups confidential epics and epics from ancestors' do
                  finder_params[:include_ancestor_groups] = true

                  expect(finder.execute)
                    .to contain_exactly(subgroup_epic, subgroup2_epic, confidential_epic)
                end
              end
            end

            context 'when include_descendant_groups is false' do
              context 'and include_ancestor_groups is false' do
                let(:finder_params) { { include_descendant_groups: false, include_ancestor_groups: false } }

                it { is_expected.to contain_exactly(subgroup_epic) }
              end

              context 'and include_ancestor_groups is true' do
                let(:finder_params) { { include_descendant_groups: false, include_ancestor_groups: true } }

                it { is_expected.to contain_exactly(subgroup_epic, epic1, epic2, epic3, epic5) }

                context "when user does not have permission to view ancestor groups" do
                  let(:finder_params) { { group_id: subgroup.id, include_descendant_groups: false, include_ancestor_groups: true } }

                  subject { described_class.new(subgroup_guest, finder_params).execute }

                  it { is_expected.to contain_exactly(subgroup_epic) }
                end
              end
            end

            context 'when include_descendant_groups is true (by default)' do
              context 'and include_ancestor_groups is false' do
                let(:finder_params) { { include_ancestor_groups: false } }

                it { is_expected.to contain_exactly(subgroup_epic, subgroup2_epic, confidential_epic) }
              end

              context 'and include_ancestor_groups is true' do
                let(:finder_params) { { include_ancestor_groups: true } }

                it { is_expected.to contain_exactly(subgroup_epic, subgroup2_epic, epic1, epic2, epic3, epic5, confidential_epic) }

                context "when user does not have permission to view ancestor groups" do
                  let(:finder_params) { { group_id: subgroup.id, include_ancestor_groups: true } }

                  subject { described_class.new(subgroup_guest, finder_params).execute }

                  it { is_expected.to contain_exactly(subgroup_epic, subgroup2_epic) }
                end
              end
            end

            context 'when user is a guest of top level group' do
              it 'does not have N+1 queries for subgroups' do
                GroupMember.where(user_id: search_user.id).delete_all
                group.add_guest(search_user)

                epics.to_a # cache warm up
                ::Gitlab::SafeRequestStore.clear!

                control = ActiveRecord::QueryRecorder.new(skip_cached: false) { epics.to_a }

                create_list(:group, 5, :private, parent: group)
                ::Gitlab::SafeRequestStore.clear!

                expect { epics.to_a }.not_to exceed_all_query_limit(control)
              end
            end
          end

          it 'does not execute more than 5 SQL queries' do
            expect { epics.to_a }.not_to exceed_all_query_limit(5)
          end

          it 'does not execute more than 6 SQL queries when checking namespace plans', :saas do
            allow(Gitlab::CurrentSettings)
              .to receive(:should_check_namespace_plan?)
              .and_return(true)

            create(:gitlab_subscription, :ultimate, namespace: group)

            expect { epics.to_a }.not_to exceed_all_query_limit(6)
          end
        end

        context 'by timeframe' do
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

        context 'by parent' do
          before do
            epic3.update!(parent_id: epic2.id)
            epic2.update!(parent_id: epic1.id)
          end

          it 'returns direct children of the parent' do
            params = { parent_id: epic1.id }

            expect(epics(params)).to contain_exactly(epic2)
          end

          context 'when `top_level_hierarchy_only` param is true' do
            let_it_be(:ancestor) { create(:group) }
            let_it_be(:base_group) { create(:group, parent: ancestor) }
            let_it_be(:descendant) { create(:group, parent: base_group) }
            let_it_be(:parent_base) { create(:epic, group: base_group) }
            let_it_be(:parent_ancestor) { create(:epic, group: ancestor) }
            let_it_be(:parent_other) { create(:epic, group: another_group) }
            let_it_be(:parent_descendant) { create(:epic, group: descendant) }
            let_it_be(:with_ancestor_parent) { create(:epic, group: base_group, parent: parent_ancestor) }
            let_it_be(:with_other_parent) { create(:epic, group: base_group, parent: parent_other) }
            let_it_be(:with_descendant_parent) { create(:epic, group: base_group, parent: parent_descendant) }
            let_it_be(:with_group_parent) { create(:epic, group: base_group, parent: parent_base) }
            let_it_be(:with_no_parent) { create(:epic, group: base_group) }

            let(:params) { { group_id: base_group.id, top_level_hierarchy_only: true } }

            shared_examples 'epics excluding children in group hierarchy' do
              it 'excludes children with parents in scoped groups' do
                expected = [parent_base, with_other_parent, with_no_parent]
                epics = epics(finder_params)

                expect(epics).to match_array(expected + expected_by_params)
              end
            end

            context 'when include_descendant_groups is true' do
              let(:epic_params) { params.merge(include_descendant_groups: true) }

              it_behaves_like 'epics excluding children in group hierarchy' do
                let(:finder_params) { epic_params }

                let(:expected_by_params) { [parent_descendant, with_ancestor_parent] }
              end

              context 'when include_ancestor_groups is true' do
                let(:finder_params) { epic_params.merge(include_ancestor_groups: true) }

                it_behaves_like 'epics excluding children in group hierarchy' do
                  let(:expected_by_params) { [parent_descendant, parent_ancestor] }
                end
              end
            end

            context 'when include_descendant_groups is false' do
              let(:epic_params) { params.merge(include_descendant_groups: false) }

              it_behaves_like 'epics excluding children in group hierarchy' do
                let(:finder_params) { epic_params }

                let(:expected_by_params) { [with_ancestor_parent, with_descendant_parent] }
              end

              context 'when include_ancestor_groups is true' do
                let(:finder_params) { epic_params.merge(include_ancestor_groups: true) }

                it_behaves_like 'epics excluding children in group hierarchy' do
                  let(:expected_by_params) { [parent_ancestor, with_descendant_parent] }
                end
              end
            end

            context 'when `parent_id` param is present' do
              let(:epic_params) { params.merge({ exclude_group_children: true, parent_id: parent_base.id }) }

              it 'ignores top_level_hierarchy_only param and returns direct children of the parent' do
                expect(epics(epic_params)).to contain_exactly(with_group_parent)
              end
            end
          end
        end

        context 'by child' do
          before do
            epic3.update!(parent_id: epic2.id)
            epic2.update!(parent_id: epic1.id)
          end

          it 'returns ancestors of the child epic ordered from the bottom' do
            params = { child_id: epic5.id, hierarchy_order: :asc }

            expect(epics(params)).to eq([epic3, epic2, epic1])
          end

          it 'returns ancestors of the child epic ordered from the top if requested' do
            params = { child_id: epic5.id, hierarchy_order: :desc }

            expect(epics(params)).to eq([epic1, epic2, epic3])
          end
        end

        context 'by confidential' do
          let_it_be(:confidential_epic) { create(:epic, :confidential, group: group) }

          it 'returns only confidential epics when confidential is true' do
            params = { confidential: true }

            expect(epics(params)).to contain_exactly(confidential_epic)
          end

          it 'does not include confidential epics when confidential is false' do
            params = { confidential: false }

            expect(epics(params)).not_to include(confidential_epic)
          end
        end

        context 'by iids' do
          let_it_be(:subgroup) { create(:group, :private, parent: group) }
          let_it_be(:subepic1) { create(:epic, group: subgroup, iid: epic1.iid) }

          it 'returns the specified epics' do
            params = { iids: [epic1.iid, epic2.iid] }

            expect(epics(params)).to contain_exactly(epic1, epic2)
          end

          it 'does not return epics from the sub-group with the same iid' do
            params = { iids: [epic1.iid] }

            expect(epics(params)).to contain_exactly(epic1)
          end
        end

        context 'by milestone' do
          let_it_be(:ancestor_group) { create(:group, :public) }
          let_it_be(:ancestor_group_project) { create(:project, :public, group: ancestor_group) }
          let_it_be(:base_group) { create(:group, :public, parent: ancestor_group) }
          let_it_be(:base_group_project) { create(:project, :public, group: base_group) }
          let_it_be(:base_epic1) { create(:epic, group: base_group) }
          let_it_be(:base_epic2) { create(:epic, group: base_group) }
          let_it_be(:base_group_milestone) { create(:milestone, group: base_group) }
          let_it_be(:base_project_milestone) { create(:milestone, project: base_group_project) }

          shared_examples 'filtered by milestone' do
            it 'returns expected epics' do
              create(:issue, project: project, milestone: milestone, epic: epic)
              create(:issue, project: project, milestone: milestone, epic: epic2)

              params[:milestone_title] = milestone.title

              expect(epics(params)).to contain_exactly(epic, epic2)
            end
          end

          context 'with no hierarchy' do
            let_it_be(:project) { base_group_project }
            let_it_be(:epic) { base_epic1 }
            let_it_be(:epic2) { base_epic2 }
            let_it_be(:params) do
              {
                  group_id: base_group.id,
                  include_descendant_groups: false,
                  include_ancestor_groups: false
              }
            end

            it_behaves_like 'filtered by milestone' do
              let_it_be(:milestone) { base_group_milestone }
            end

            it_behaves_like 'filtered by milestone' do
              let_it_be(:milestone) { base_project_milestone }
            end

            it 'returns empty result if the milestone is not present' do
              params[:milestone_title] = 'test milestone title'

              expect(epics(params)).to be_empty
            end
          end

          context "with hierarchy" do
            let_it_be(:subgroup) { create(:group, :public, parent: base_group) }
            let_it_be(:subgroup_project) { create(:project, :public, group: subgroup) }
            let_it_be(:subgroup_project_milestone) { create(:milestone, project: subgroup_project) }
            let_it_be(:ancestor_group_milestone) { create(:milestone, group: ancestor_group) }
            let_it_be(:ancestor_project_milestone) { create(:milestone, project: ancestor_group_project) }
            let_it_be(:subgroup_epic1) { create(:epic, group: subgroup) }
            let_it_be(:subgroup_epic2) { create(:epic, group: subgroup) }
            let_it_be(:ancestor_epic1) { create(:epic, group: ancestor_group) }
            let_it_be(:ancestor_epic2) { create(:epic, group: ancestor_group) }
            let_it_be(:params) { { group_id: base_group.id } }

            context 'when include_descendant_groups is true' do
              let_it_be(:project) { subgroup_project }
              let_it_be(:epic) { subgroup_epic1 }
              let_it_be(:epic2) { subgroup_epic2 }

              before do
                params[:include_descendant_groups] = true
                params[:include_ancestor_groups] = false
              end

              it_behaves_like 'filtered by milestone', :group do
                let(:milestone) { base_group_milestone }
              end

              it_behaves_like 'filtered by milestone', :project do
                let(:milestone) { subgroup_project_milestone }
              end

              it 'returns results with all milestones matching given title' do
                project_milestone1 = create(:milestone, project: base_group_project, title: '13.0')
                project_milestone2 = create(:milestone, project: subgroup_project, title: '13.0')
                create(:issue, project: base_group_project, milestone: project_milestone1, epic: base_epic1)
                create(:issue, project: subgroup_project, milestone: project_milestone2, epic: subgroup_epic1)

                params[:milestone_title] = '13.0'

                expect(epics(params)).to contain_exactly(base_epic1, subgroup_epic1)
              end
            end

            context 'when include_ancestor_groups is true' do
              let_it_be(:project) { ancestor_group_project }
              let_it_be(:epic) { ancestor_epic1 }
              let_it_be(:epic2) { ancestor_epic2 }

              before do
                params[:include_descendant_groups] = false
                params[:include_ancestor_groups] = true
              end

              it_behaves_like 'filtered by milestone', :group do
                let(:milestone) { ancestor_group_milestone }
              end

              it_behaves_like 'filtered by milestone', :project do
                let(:milestone) { ancestor_project_milestone }
              end

              context 'when include_descendant_groups is true' do
                before do
                  params[:include_descendant_groups] = true
                end

                it 'returns expected epics when filtering by group milestone' do
                  create(:issue, project: ancestor_group_project, milestone: ancestor_group_milestone, epic: ancestor_epic1)
                  create(:issue, project: base_group_project, milestone: ancestor_group_milestone, epic: ancestor_epic1)
                  create(:issue, project: subgroup_project, milestone: ancestor_group_milestone, epic: subgroup_epic1)

                  params[:milestone_title] = ancestor_group_milestone.title

                  expect(epics(params)).to contain_exactly(ancestor_epic1, subgroup_epic1)
                end

                it_behaves_like 'filtered by milestone', :project do
                  let(:milestone) { ancestor_project_milestone }
                end
              end

              context 'when a project is restricted' do
                let_it_be(:issue) do
                  create(:issue, project: subgroup_project, epic: subgroup_epic1, milestone: subgroup_project_milestone)
                end

                before do
                  params[:milestone_title] = subgroup_project_milestone.title
                end

                it 'does not return epic if user can not access project' do
                  subgroup_project
                    .update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

                  expect(epics(params)).to be_empty
                end

                it 'does not return epics if user can not access project issues' do
                  subgroup_project
                    .project_feature.update!( issues_access_level: ProjectFeature::DISABLED)

                  expect(epics(params)).to be_empty
                end
              end
            end
          end
        end

        context 'when using iid starts with query' do
          let_it_be(:epic1) { create(:epic, :opened, group: group, iid: '11') }
          let_it_be(:epic2) { create(:epic, :opened, group: group, iid: '1112') }
          let_it_be(:epic3) { create(:epic, :closed, group: group, iid: '9978') }
          let_it_be(:epic4) { create(:epic, :closed, group: another_group, iid: '111') }

          it 'returns the expected epics if just the first two numbers are given' do
            params = { iid_starts_with: '11' }

            expect(epics(params)).to contain_exactly(epic1, epic2)
          end

          it 'returns the expected epics if the exact id is given' do
            params = { iid_starts_with: '1112' }

            expect(epics(params)).to contain_exactly(epic2)
          end

          it 'is empty if the last number is given' do
            params = { iid_starts_with: '8' }

            expect(epics(params)).to be_empty
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

        context 'when using group cte for search' do
          context 'and two labels more search string are present' do
            let_it_be(:label1) { create(:group_label, group: group) }
            let_it_be(:label2) { create(:group_label, group: group) }
            let_it_be(:labeled_epic) { create(:labeled_epic, group: group, title: 'filtered epic', labels: [label1, label2]) }

            it 'returns correct epics' do
              filtered_epics =
                epics(attempt_group_search_optimizations: true, label_name: [label1.title, label2.title], search: 'filtered')

              expect(filtered_epics).to contain_exactly(labeled_epic)
            end

            it 'filters correctly by short expressions when sorting by due date' do
              expect(epics(attempt_group_search_optimizations: true, search: 'aw', sort: 'end_date_desc'))
                .to eq([epic3, epic1])
            end
          end
        end

        context 'with confidential epics' do
          let_it_be(:ancestor_group) { create(:group, :public) }
          let_it_be(:base_group) { create(:group, :public, parent: ancestor_group) }
          let_it_be(:base_epic1) { create(:epic, :confidential, group: base_group) }
          let_it_be(:base_epic2) { create(:epic, group: base_group) }
          let_it_be(:private_group1) { create(:group, :private, parent: base_group) }
          let_it_be(:private_epic1) { create(:epic, group: private_group1) }
          let_it_be(:private_epic2) { create(:epic, :confidential, group: private_group1) }
          let_it_be(:public_group1) { create(:group, :public, parent: base_group) }
          let_it_be(:public_epic1) { create(:epic, group: public_group1) }
          let_it_be(:public_epic2) { create(:epic, :confidential, group: public_group1) }
          let_it_be(:internal_group) { create(:group, :internal, parent: base_group) }
          let_it_be(:internal_epic) { create(:epic, group: internal_group) }

          let(:execute_params) { {} }

          def execute
            described_class.new(search_user, group_id: base_group.id).execute(**execute_params)
          end

          shared_examples 'avoids N+1 queries' do
            it 'avoids N+1 queries on searched groups' do
              execute # warm up
              control = ActiveRecord::QueryRecorder.new(skip_cached: false) { execute }

              create_list(:group, 5, :private, parent: base_group)

              expect { execute }.not_to exceed_all_query_limit(control)
            end
          end

          context 'when user is not set' do
            let(:search_user) { nil }

            it 'returns only public epics in public groups' do
              expect(execute).to match_array([base_epic2, public_epic1])
            end

            it_behaves_like 'avoids N+1 queries'
          end

          context 'when user is not member of any groups being searched' do
            it 'returns only public epics in public and internal groups' do
              expect(execute).to match_array([base_epic2, public_epic1, internal_epic])
            end

            it_behaves_like 'avoids N+1 queries'
          end

          context 'when skip_visibility_check is true' do
            let(:execute_params) { { skip_visibility_check: true } }

            it 'returns all epics' do
              expect(execute).to match_array([base_epic1, base_epic2, private_epic1, private_epic2, public_epic1, public_epic2, internal_epic])
            end
          end

          context 'when user is member of ancestor group' do
            before do
              ancestor_group.add_developer(search_user)
            end

            it 'returns all nested epics' do
              expect(execute).to match_array([base_epic1, base_epic2, private_epic1, private_epic2, public_epic1, public_epic2, internal_epic])
            end

            it_behaves_like 'avoids N+1 queries'

            it 'does not check permission for subgroups because user inherits permission' do
              finder = described_class.new(search_user, group_id: base_group.id)

              expect(finder).not_to receive(:groups_user_can_read_epics)

              finder.execute
            end
          end

          context 'when user is member of private subgroup' do
            before do
              private_group1.add_developer(search_user)
            end

            it 'returns also confidential epics from this subgroup' do
              expect(execute).to match_array([base_epic2, private_epic1, private_epic2, public_epic1, internal_epic])
            end

            # if user is not member of top-level group, we need to check
            # if he can read epics in each subgroup
            it 'does not execute more than 17 SQL queries' do
              # The limit here is fragile!
              expect { execute }.not_to exceed_all_query_limit(17)
            end

            it 'checks permission for each subgroup' do
              finder = described_class.new(search_user, group_id: base_group.id)

              expect(finder).to receive(:groups_user_can_read_epics).and_call_original

              finder.execute
            end
          end

          context 'when user is a guest in the base group' do
            before do
              base_group.add_guest(search_user)
            end

            it 'does not return any confidential epics in the base or subgroups' do
              expect(execute).to match_array([base_epic2, private_epic1, public_epic1, internal_epic])
            end
          end

          context 'when user is member of public subgroup' do
            before do
              public_group1.add_developer(search_user)
            end

            it 'returns also confidential epics from this subgroup' do
              expect(execute).to match_array([base_epic2, public_epic1, public_epic2, internal_epic])
            end
          end
        end

        context 'with negated labels' do
          let_it_be(:label) { create(:group_label, group: group) }
          let_it_be(:label2) { create(:group_label, group: group) }
          let_it_be(:negated_epic) { create(:labeled_epic, group: group, labels: [label]) }
          let_it_be(:negated_epic2) { create(:labeled_epic, group: group, labels: [label2]) }
          let_it_be(:params) { { not: { label_name: [label.title, label2.title].join(',') } } }

          it 'returns all epics if no negated labels are present' do
            expect(epics).to contain_exactly(negated_epic, negated_epic2, epic1, epic2, epic3, epic5)
          end

          it 'returns all epics without negated label' do
            expect(epics(params)).to contain_exactly(epic1, epic2, epic3, epic5)
          end
        end

        context 'with negated author' do
          let_it_be(:author) { create(:user) }
          let_it_be(:authored_epic) { create(:epic, group: group, author: author) }
          let_it_be(:params) { { not: { author_id: author.id } } }

          it 'returns all epics if no negated author is present' do
            expect(epics).to contain_exactly(authored_epic, epic1, epic2, epic3, epic5)
          end

          it 'returns all epics without given author' do
            expect(epics(params)).to contain_exactly(epic1, epic2, epic3, epic5)
          end
        end

        context 'with negated reaction emoji' do
          let_it_be(:awarded_emoji) { create(:award_emoji, name: 'thumbsup', awardable: epic3, user: search_user) }
          let_it_be(:params) { { not: { my_reaction_emoji: awarded_emoji.name } } }

          it 'returns all epics without given emoji name' do
            expect(epics(params)).to contain_exactly(epic1, epic2, epic5)
          end
        end
      end
    end
  end

  describe '.valid_iid_query?' do
    using RSpec::Parameterized::TableSyntax

    where(:query, :expected_result) do
      "foo" | false
      "-1" | false
      "1\nfoo" | false
      "foo\n1" | false
      "1" | true
    end

    with_them do
      subject { described_class.valid_iid_query?(query) }

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#row_count' do
    let_it_be(:label) { create(:group_label, group: group) }
    let_it_be(:label2) { create(:group_label, group: group) }
    let_it_be(:labeled_epic) { create(:labeled_epic, group: group, labels: [label]) }
    let_it_be(:labeled_epic2) { create(:labeled_epic, group: group, labels: [label, label2]) }

    before do
      group.add_developer(search_user)
      stub_licensed_features(epics: true)
    end

    it 'returns number of rows when epics are grouped' do
      params = { group_id: group.id, label_name: [label.title, label2.title] }

      expect(described_class.new(search_user, params).row_count).to eq(1)
    end
  end

  describe '#count_by_state' do
    before do
      group.add_developer(search_user)
      stub_licensed_features(epics: true)
    end

    it 'returns correct counts' do
      results = described_class.new(search_user, group_id: group.id).count_by_state

      expect(results).to eq('opened' => 3, 'closed' => 1, 'all' => 4)
    end

    it 'returns -1 if the query times out' do
      finder = described_class.new(search_user, group_id: group.id)

      expect_next_instance_of(described_class) do |subfinder|
        expect(subfinder).to receive(:execute).and_raise(ActiveRecord::QueryCanceled)
      end

      expect(finder.row_count).to eq(-1)
    end

    context 'when using group cte for search' do
      it 'returns correct counts when search string is used' do
        results = described_class.new(
          search_user,
          group_id: group.id,
          search: 'awesome',
          attempt_group_search_optimizations: true
        ).count_by_state

        expect(results).to eq('opened' => 1, 'closed' => 1, 'all' => 2)
      end
    end
  end
end
