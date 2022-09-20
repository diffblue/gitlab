# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting child epics of an epic' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, :private, parent: group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:child_a) { create(:epic, group: group, parent: epic) }
  let_it_be(:child_b) { create(:epic, group: subgroup, parent: epic) }

  let(:epic_node) do
    <<~NODE
      edges {
        node {
          id
          iid
          children {
            edges {
              node {
                iid
                title
                labels {
                  edges {
                    node {
                      title
                      color
                      description
                    }
                  }
                }
              }
            }
          }
        }
      }
    NODE
  end

  def query(params = {})
    graphql_query_for(
      "group", { "fullPath" => group.full_path },
      ['epicsEnabled', query_graphql_field("epics", params, epic_node)]
    )
  end

  def children_data_array(attribute)
    graphql_data_at(:group, :epics, :edges, :node, :children, :edges, :node, attribute)
  end

  context 'when epics are enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    it 'finds children from group public' do
      post_graphql(query(iid: epic.iid), current_user: user)

      expect(children_data_array(:iid)).to contain_exactly(child_a.iid.to_s)
    end

    context 'with access to private subgroup' do
      before do
        subgroup.add_developer(user)
      end

      it 'finds children from group and subgroup' do
        post_graphql(query(iid: epic.iid), current_user: user)

        expect(children_data_array(:iid)).to contain_exactly(child_a.iid.to_s, child_b.iid.to_s)
      end
    end

    context 'when multiple children include labels' do
      let_it_be(:label) { create(:group_label, group: group) }
      let_it_be(:label_link1) { create(:label_link, label: label, target: child_a) }
      let_it_be(:label_link2) { create(:label_link, label: label, target: child_b) }

      before do
        post_graphql(query(iid: epic.iid), current_user: user) # warm up
      end

      it 'does not execute extra N+1 queries for labels' do
        control = ActiveRecord::QueryRecorder.new do
          post_graphql(query(iid: epic.iid), current_user: user)
        end

        child_c = create(:epic, group: group, parent: epic)
        create(:label_link, label: label, target: child_c)

        subgroup2 = create(:group, :private, parent: group)
        subgroup3 = create(:group, :private, parent: group)
        subgroup4 = create(:group, :private, parent: group)

        child_d = create(:epic, group: subgroup2, parent: epic)
        child_e = create(:epic, group: subgroup3, parent: epic)
        child_f = create(:epic, group: subgroup4, parent: epic)

        label2 = create(:group_label, group: subgroup2)
        label3 = create(:group_label, group: subgroup3)
        label4 = create(:group_label, group: subgroup4)

        create(:label_link, label: label2, target: child_d)
        create(:label_link, label: label3, target: child_e)
        create(:label_link, label: label4, target: child_f)

        # Permission checks perform N+1 queries.
        expect { post_graphql(query(iid: epic.iid), current_user: user) }
          .not_to exceed_all_query_limit(control).with_threshold(2)
      end
    end
  end
end
