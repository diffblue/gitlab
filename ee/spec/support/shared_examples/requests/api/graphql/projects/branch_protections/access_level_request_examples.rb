# frozen_string_literal: true

RSpec.shared_examples 'AccessLevel type objects contains user and group' do |access_level_kind|
  let_it_be(:protected_branch) do
    create(:protected_branch, "user_can_#{access_level_kind}", "group_can_#{access_level_kind}", project: project)
  end

  let(:user_access_level) { access_levels.for_user.first }
  let(:group_access_level) { access_levels.for_group.first }
  let(:user_access_level_data) { access_levels_data.find { |data| data['user'].present? } }
  let(:group_access_level_data) { access_levels_data.find { |data| data['group'].present? } }

  before do
    post_graphql(query, current_user: current_user, variables: variables)
  end

  context 'when request AccessLevel type objects as a maintainer' do
    it_behaves_like 'a working graphql query'

    it 'returns all the access level attributes' do
      expect(user_access_level_data['accessLevel']).to eq(user_access_level.access_level)
      expect(user_access_level_data['accessLevelDescription']).to eq(user_access_level.humanize)
      expect(user_access_level_data.dig('user', 'name')).to eq(user_access_level.user.name)
      expect(user_access_level_data.dig('group', 'name')).to be_nil

      expect(group_access_level_data['accessLevel']).to eq(group_access_level.access_level)
      expect(group_access_level_data['accessLevelDescription']).to eq(group_access_level.humanize)
      expect(group_access_level_data.dig('group', 'name')).to eq(group_access_level.group.name)
      expect(group_access_level_data.dig('user', 'name')).to be_nil
    end
  end
end
