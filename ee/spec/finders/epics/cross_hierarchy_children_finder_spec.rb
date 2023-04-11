# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::CrossHierarchyChildrenFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:search_user) { create(:user) }
  let_it_be(:ancestor) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: ancestor) }
  let_it_be(:subgroup) { create(:group, :private, parent: group) }

  let_it_be(:parent_epic) { create(:epic, :opened, group: group) }
  let_it_be(:group_epic) { create(:epic, :opened, group: group, parent: parent_epic) }
  let_it_be(:confidential_group_epic) { create(:epic, :opened, :confidential, group: group, parent: parent_epic) }
  let_it_be(:ancestor_epic) { create(:epic, :opened, group: ancestor, parent: parent_epic) }
  let_it_be(:subgroup_epic) { create(:epic, :opened, group: subgroup, parent: parent_epic) }

  it_behaves_like 'epic findable finder'

  describe '#execute' do
    let(:finder_params) { { parent: parent_epic } }
    let(:parent_param) { parent_epic }

    def epics(params = {})
      params[:parent] ||= parent_param

      described_class.new(search_user, params).execute
    end

    context 'when epics feature is enabled', :request_store do
      before do
        stub_licensed_features(epics: true)
      end

      context 'without param' do
        it 'raises an error when parent param is missing' do
          expect { described_class.new(search_user).execute }
            .to raise_error(ArgumentError, 'parent argument is missing')
        end
      end

      context 'when user can not read parent epic' do
        it 'returns empty collection' do
          expect(epics).to be_empty
        end
      end

      context "when user has guest access" do
        before do
          [group, ancestor, subgroup].each { |g| g.add_guest(search_user) }
        end

        it 'returns all child epics' do
          expect(epics).to contain_exactly(group_epic, ancestor_epic, subgroup_epic)
        end

        context 'when param include_ancestor_groups is `false`' do
          it 'returns all child epics excluding the ones in ancestor groups' do
            expect(epics({ include_ancestor_groups: false }))
              .to contain_exactly(group_epic, subgroup_epic)
          end
        end

        context 'when param include_descendant_groups is `false`' do
          it 'returns all child epics excluding the ones in descendant groups' do
            expect(epics({ include_descendant_groups: false }))
              .to contain_exactly(group_epic, ancestor_epic)
          end
        end

        context 'when param include_ancestor_groups and include_descendant_groups are `false`' do
          it 'returns all child epics excluding the ones in ancestor and descendant groups' do
            expect(epics({ include_ancestor_groups: false,  include_descendant_groups: false }))
              .to contain_exactly(group_epic)
          end
        end
      end

      context 'when user has reporter access to parent epic group' do
        before do
          ancestor.add_reporter(search_user)
          group.add_reporter(search_user)
        end

        it 'returns visible child epics' do
          expect(epics).to contain_exactly(group_epic, ancestor_epic, subgroup_epic, confidential_group_epic)
        end

        context 'with children in a different group hierarchy' do
          let_it_be(:other_ancestor) { create(:group, :private) }
          let_it_be(:other_group) { create(:group, :private, parent: other_ancestor) }
          let_it_be(:other_subgroup) { create(:group, :private, parent: other_group) }

          let_it_be(:other_ancestor_epic) do
            create(:epic, :opened, group: other_ancestor, parent: parent_epic)
          end

          let_it_be(:other_group_epic) do
            create(:epic, :opened, group: other_group, parent: parent_epic)
          end

          let_it_be(:other_subgroup_epic) do
            create(:epic, :opened, group: other_subgroup, parent: parent_epic)
          end

          context 'when preload is `true`' do
            before do
              allow(Group).to receive(:preload_root_saml_providers).and_return(Group.all)
            end

            it 'calls method to preload groups relationships' do
              finder = described_class.new(search_user, { parent: parent_epic })

              expect(Group).to receive(:preload_root_saml_providers)

              finder.execute(preload: true)
            end
          end

          context 'when user is member of private top level group' do
            before do
              other_ancestor.add_developer(search_user)
            end

            it 'returns all visible child epics' do
              expect(epics).to contain_exactly(
                group_epic,
                ancestor_epic,
                subgroup_epic,
                confidential_group_epic,
                other_ancestor_epic,
                other_group_epic,
                other_subgroup_epic
              )
            end
          end

          context 'when user is member of private base group' do
            before do
              other_group.add_developer(search_user)
            end

            it 'returns all visible child epics' do
              expect(epics).to contain_exactly(
                group_epic,
                ancestor_epic,
                subgroup_epic,
                confidential_group_epic,
                other_group_epic,
                other_subgroup_epic
              )
            end
          end

          context 'when user is member of private other_subgroup' do
            before do
              other_subgroup.add_developer(search_user)
            end

            it 'returns all visible child epics' do
              expect(epics).to contain_exactly(
                group_epic,
                ancestor_epic,
                subgroup_epic,
                confidential_group_epic,
                other_subgroup_epic
              )
            end
          end

          context 'with group hierarchy with projects' do
            let_it_be(:ancestor_project) { create(:project, :private, group: other_ancestor) }
            let_it_be(:base_project) { create(:project, :private, group: other_group) }
            let_it_be(:subproject) { create(:project, :private, group: other_subgroup) }

            context 'when user is member of top level group project' do
              before do
                ancestor_project.add_developer(search_user)
              end

              it 'returns child epics in projects group and its ancestors' do
                expect(epics).to contain_exactly(
                  group_epic,
                  ancestor_epic,
                  subgroup_epic,
                  confidential_group_epic,
                  other_ancestor_epic
                )
              end
            end

            context 'when user is member of a base group project' do
              before do
                base_project.add_developer(search_user)
              end

              it 'returns child epics in projects group and its ancestors' do
                expect(epics).to contain_exactly(
                  group_epic,
                  ancestor_epic,
                  subgroup_epic,
                  confidential_group_epic,
                  other_ancestor_epic,
                  other_group_epic
                )
              end
            end

            context 'when user is member of the other_subgroup project' do
              before do
                subproject.add_developer(search_user)
              end

              it 'returns child epics in projects group and its ancestors' do
                expect(epics).to contain_exactly(
                  group_epic,
                  ancestor_epic,
                  subgroup_epic,
                  confidential_group_epic,
                  other_ancestor_epic,
                  other_group_epic,
                  other_subgroup_epic
                )
              end
            end
          end

          context 'with shared groups' do
            let_it_be(:shared_group) { create(:group) }

            before do
              shared_group.add_developer(search_user)
            end

            context 'when user is member of a group shared with the top level group' do
              let_it_be(:group_group_link) do
                create(:group_group_link, shared_group: other_ancestor, shared_with_group: shared_group)
              end

              it 'returns child epics in top level group and its descendants' do
                expect(epics).to contain_exactly(
                  group_epic,
                  ancestor_epic,
                  subgroup_epic,
                  confidential_group_epic,
                  other_ancestor_epic,
                  other_group_epic,
                  other_subgroup_epic
                )
              end
            end

            context 'when user is member of a group shared with the base group' do
              let_it_be(:group_group_link) do
                create(:group_group_link, shared_group: other_group, shared_with_group: shared_group)
              end

              it 'returns child epics in the base group and its descendants' do
                expect(epics).to contain_exactly(
                  group_epic,
                  ancestor_epic,
                  subgroup_epic,
                  confidential_group_epic,
                  other_group_epic,
                  other_subgroup_epic
                )
              end
            end

            context 'when user is member of a group shared with the subgroup' do
              let_it_be(:group_group_link) do
                create(:group_group_link, shared_group: other_subgroup, shared_with_group: shared_group)
              end

              it 'returns child epics in the other_subgroup' do
                expect(epics).to contain_exactly(
                  group_epic,
                  ancestor_epic,
                  subgroup_epic,
                  confidential_group_epic,
                  other_subgroup_epic
                )
              end
            end
          end

          it_behaves_like 'epics hierarchy finder with filtering' do
            let(:base_param) { :parent }
            let(:sort_order) { :desc }
            let(:parent_param) { epic4 }
            let_it_be(:reference_time) { Time.parse('2020-09-15 01:00') }

            let_it_be(:another_group) { create(:group) }
            let_it_be(:label) { create(:group_label, group: group) }
            let_it_be_with_reload(:epic4) do
              create(
                :epic,
                group: group,
                start_date: 6.days.before(reference_time),
                end_date: 6.days.before(reference_time),
                iid: 8876
              )
            end

            let_it_be_with_reload(:epic3) do
              create(
                :epic, :closed, parent: epic4,
                group: another_group,
                description: 'not so awesome',
                start_date: 5.days.before(reference_time),
                end_date: 3.days.before(reference_time),
                iid: 6873
              )
            end

            let_it_be_with_reload(:epic2) do
              create(
                :epic, :opened, parent: epic4,
                group: group,
                created_at: 4.days.before(reference_time),
                author: user,
                start_date: 2.days.before(reference_time),
                end_date: 3.days.since(reference_time),
                iid: 9834
              )
            end

            let_it_be(:epic1) do
              create(
                :epic, :opened, parent: epic4,
                group: another_group,
                title: 'This is awesome epic',
                created_at: 1.week.before(reference_time),
                end_date: 10.days.before(reference_time),
                labels: [label],
                iid: 9835
              )
            end

            let_it_be(:public_group) { create(:group, :public) }
            let_it_be(:epic7) { create(:epic, group: public_group) }
            let_it_be(:epic5) { create(:epic, group: public_group, parent: epic7, title: 'tanuki') }
            let_it_be(:epic6) { create(:epic, group: public_group, parent: epic7, title: 'ikunat') }
          end
        end
      end
    end
  end
end
