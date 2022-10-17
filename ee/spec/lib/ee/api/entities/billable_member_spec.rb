# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::API::Entities::BillableMember do
  let_it_be(:last_activity_on) { Date.today - 1.day }
  let_it_be(:current_sign_in_at) { DateTime.now - 2.days }
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, last_activity_on: last_activity_on, current_sign_in_at: current_sign_in_at) }
  let_it_be(:member) { create(:group_member, :owner, user: user, group: group) }

  let(:options) do
    {
      group: group,
      current_user: user,
      group_member_user_ids: [],
      project_member_user_ids: [],
      shared_group_user_ids: [],
      shared_project_user_ids: []
    }
  end

  subject(:entity_representation) { described_class.new(user, options).as_json }

  it 'returns the last_activity_on attribute' do
    expect(entity_representation[:last_activity_on]).to eq last_activity_on
  end

  it 'exposes the last_login_at field' do
    expect(entity_representation[:last_login_at]).to eq current_sign_in_at
  end

  it 'exposes the created_at field' do
    expect(entity_representation[:created_at]).to eq(user.created_at)
  end

  it 'exposes the is_last_owner field' do
    expect(entity_representation[:is_last_owner]).to eq(true)
  end

  context 'when the user has a public_email assigned' do
    let_it_be(:public_email_address) { 'public@email.com' }

    before do
      create(:email, :confirmed, user: user, email: public_email_address)
      user.update!(public_email: public_email_address)
    end

    it 'exposes public_email instead of email' do
      aggregate_failures do
        expect(entity_representation.keys).to include(:email)
        expect(entity_representation[:email]).to eq public_email_address
        expect(entity_representation[:email]).not_to eq user.email
      end
    end
  end

  context 'when the user has no public_email assigned' do
    before do
      user.update!(public_email: nil)
    end

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
      let(:options) { super().merge(user_ids => [user.id]) }

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
