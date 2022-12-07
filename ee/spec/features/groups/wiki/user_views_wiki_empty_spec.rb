# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group > User views empty wiki', feature_category: :wiki do
  include WikiHelpers

  let_it_be(:user) { create(:user) }

  let(:wiki) { create(:group_wiki, group: group) }

  before do
    stub_group_wikis(true)
  end

  it_behaves_like 'User views empty wiki' do
    context 'when group is public' do
      let(:group) { create(:group, :public) }

      it_behaves_like 'empty wiki message'

      context 'and user is logged in' do
        before do
          sign_in(user)
        end

        context 'and user is not a member' do
          it_behaves_like 'empty wiki message'
        end

        context 'and user is a member' do
          before do
            group.add_developer(user)
          end

          it_behaves_like 'empty wiki message', writable: true
        end
      end
    end

    context 'when group is private' do
      let(:group) { create(:group, :private) }

      it_behaves_like 'wiki is not found'

      context 'and user is logged in' do
        before do
          sign_in(user)
        end

        context 'and user is not a member' do
          it_behaves_like 'wiki is not found'
        end

        context 'and user is a member' do
          before do
            group.add_developer(user)
          end

          it_behaves_like 'empty wiki message', writable: true
        end
      end
    end
  end
end
