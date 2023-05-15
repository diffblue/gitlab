# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a multi-assignable resource' do
  let_it_be(:user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:assignees) { create_list(:user, 3) }

    let(:mode) { Types::MutationOperationModeEnum.default_mode }
    let(:assignee_usernames) { assignees.map(&:username) }
    let(:mutated_resource) { subject[resource.class.name.underscore.to_sym] }

    subject do
      mutation.resolve(
        project_path: resource.project.full_path,
        iid: resource.iid,
        operation_mode: mode,
        assignee_usernames: assignee_usernames
      )
    end

    before do
      assignees.each do |user|
        resource.project.add_developer(user)
      end
    end

    context 'when the user can update the resource' do
      before do
        resource.project.add_developer(user)
      end

      it 'sets the assignees' do
        expect(mutated_resource).to eq(resource)
        expect(mutated_resource.assignees).to match_array(assignees)
        expect(subject[:errors]).to be_empty
      end

      it 'removes assignees not in the list' do
        users = create_list(:user, 2)
        users.each do |user|
          resource.project.add_developer(user)
        end
        resource.assignees = users
        resource.save!

        expect(mutated_resource).to eq(resource)
        expect(mutated_resource.assignees).to match_array(assignees)
        expect(subject[:errors]).to be_empty
      end

      context 'when passing "append" as true' do
        subject { mutation.resolve(project_path: resource.project.full_path, iid: resource.iid, assignee_usernames: assignee_usernames, operation_mode: Types::MutationOperationModeEnum.enum[:append]) }

        let(:existing_assignees) { create_list(:user, 2) }

        before do
          existing_assignees.each do |user|
            resource.project.add_developer(user)
          end
          resource.assignees = existing_assignees
          resource.save!
        end

        it 'does not remove assignees not in the list' do
          expect(mutated_resource).to eq(resource)
          expect(mutated_resource.assignees).to match_array(assignees + existing_assignees)
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
