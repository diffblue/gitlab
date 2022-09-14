# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Release do
  describe '.by_namespace_id' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project_in_group) { create(:project, group: group) }
    let_it_be(:project_in_subgroup) { create(:project, group: subgroup) }
    let_it_be(:unrelated_project) { create(:project) }

    let_it_be(:release_in_group_project) { create(:release, project: project_in_group) }
    let_it_be(:release_in_subgroup_project_1) { create(:release, project: project_in_subgroup) }
    let_it_be(:release_in_subgroup_project_2) { create(:release, project: project_in_subgroup) }
    let_it_be(:release_in_unrelated_project) { create(:release, project: unrelated_project) }

    context 'when a single namespace id is passed' do
      let(:ns_id) { group.id }

      it 'returns releases associated to projects of the provided group' do
        expect(described_class.by_namespace_id(ns_id)).to match_array(
          [
            release_in_group_project
          ])
      end
    end

    context 'when an array of namespace ids is passed' do
      let(:ns_id) { group.self_and_descendants.select(:id) }

      it 'returns releases associated to projects of all provided groups' do
        expect(described_class.by_namespace_id(ns_id)).to match_array(
          [
            release_in_group_project,
            release_in_subgroup_project_1,
            release_in_subgroup_project_2
          ])
      end
    end
  end
end
