# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::API::Entities::BillableMember do
  let(:last_activity_on) { Date.today }
  let(:public_email) { nil }
  let(:member) { build(:user, id: non_existing_record_id, public_email: public_email, email: 'private@email.com', last_activity_on: last_activity_on) }
  let(:options) do
    {
      group_member_user_ids: [],
      project_member_user_ids: [],
      shared_group_user_ids: [],
      shared_project_user_ids: []
    }
  end

  subject(:entity_representation) { described_class.new(member, options).as_json }

  it 'returns the last_activity_on attribute' do
    expect(entity_representation[:last_activity_on]).to eq last_activity_on
  end

  it 'exposes the created_at field' do
    expect(entity_representation[:created_at]).to eq(member.created_at)
  end

  context 'when the user has a public_email assigned' do
    let(:public_email) { 'public@email.com' }

    it 'exposes public_email instead of email' do
      aggregate_failures do
        expect(entity_representation.keys).to include(:email)
        expect(entity_representation[:email]).to eq public_email
        expect(entity_representation[:email]).not_to eq member.email
      end
    end
  end

  context 'when the user has no public_email assigned' do
    let(:public_email) { nil }

    it 'returns a nil value for email' do
      aggregate_failures do
        expect(entity_representation.keys).to include(:email)
        expect(entity_representation[:email]).to be nil
      end
    end
  end

  context 'with different group membership types' do
    using RSpec::Parameterized::TableSyntax

    where(:user_ids, :membership_type, :removable) do
      :group_member_user_ids   | 'group_member'   | true
      :project_member_user_ids | 'project_member' | true
      :shared_group_user_ids   | 'group_invite'   | false
      :shared_project_user_ids | 'project_invite' | false
    end

    with_them do
      let(:options) { super().merge(user_ids => [member.id]) }

      it 'returns the expected membership_type value' do
        expect(entity_representation[:membership_type]).to eq membership_type
      end

      it 'returns the expected removable value' do
        expect(entity_representation[:removable]).to eq removable
      end
    end

    context 'with a missing membership type' do
      before do
        options.delete(:group_member_user_ids)
      end

      it 'does not raise an error' do
        expect(options[:group_member_user_ids]).to be_nil
        expect { entity_representation }.not_to raise_error
      end
    end
  end
end
