# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::MembersHelper, feature_category: :team_planning do
  describe '#members_page?' do
    context 'when user is on page with path: ' do
      using RSpec::Parameterized::TableSyntax

      where(:path, :is_members_page, :result) do
        'projects/project_members#index'   | true  | true
        'groups/group_members#index'       | true  | true
        'projects/project_members#index'   | false | false
        'groups/group_members#index'       | false | false
      end

      with_them do
        before do
          allow(helper).to receive(:current_path?).and_return(false)
          allow(helper).to receive(:current_path?).with(path).and_return(is_members_page)
        end

        it 'reflects if current page is members page' do
          expect(helper.members_page?).to eq(result)
        end
      end
    end
  end
end
