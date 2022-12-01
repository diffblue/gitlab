# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::UsersFinder, feature_category: :experimentation_conversion do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:invited_group) { create(:group) }

  before_all do
    group.add_developer(create(:user))
    project.add_developer(create(:user))
    group.add_guest(create(:user))
    project.add_guest(create(:user))
    invited_group.add_developer(create(:user))
    group.add_maintainer(create(:user, :project_bot))
    project.add_maintainer(create(:user, :project_bot))
    create(:group_group_link, { shared_with_group: invited_group, shared_group: group })
    create(:project_group_link, project: project, group: invited_group)
  end

  describe '#count' do
    it 'provides number of users' do
      instance = described_class.new(group).execute

      expect(instance.count).to eq(5)
    end
  end

  describe '.count' do
    it 'provides number of users' do
      expect(described_class.count(group)).to eq(5)
    end
  end
end
