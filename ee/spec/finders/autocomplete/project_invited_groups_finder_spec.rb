# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::ProjectInvitedGroupsFinder do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :private) }
    let_it_be(:public_group) { create(:group, :public) }
    let_it_be(:authorized_private_group) { create(:group, :private) }
    let_it_be(:unauthorized_private_group) { create(:group, :private) }
    let_it_be(:non_invited_group) { create(:group, :public) }

    before_all do
      authorized_private_group.add_guest(user)
      project.invited_groups = [authorized_private_group, unauthorized_private_group, public_group]
    end

    it 'raises ActiveRecord::RecordNotFound if the project does not exist' do
      finder = described_class.new(user, project_id: non_existing_record_id)

      expect { finder.execute }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises ActiveRecord::RecordNotFound if the user is not authorized to see the project' do
      finder = described_class.new(user, project_id: project.id)

      expect { finder.execute }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns an empty relation without a project ID' do
      expect(described_class.new(user).execute).to be_empty
    end

    context 'with a project the user is authorized to see' do
      before_all do
        project.add_guest(user)
      end

      it 'returns groups invited to the project that the user can see' do
        expect(described_class.new(user, project_id: project.id).execute)
          .to contain_exactly(authorized_private_group, public_group)
      end
    end
  end
end
