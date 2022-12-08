# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > User views empty wiki', feature_category: :wiki do
  let_it_be(:auditor) { create(:user, auditor: true) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:wiki) { create(:project_wiki, project: project) }

  it_behaves_like 'User views empty wiki' do
    context 'when signed in user is an Auditor' do
      before do
        sign_in(auditor)
      end

      context 'when user is not a member of the project' do
        it_behaves_like 'empty wiki message', issuable: true, expect_button: false
      end

      context 'when user is a member of the project' do
        before do
          project.add_guest(auditor)
        end

        it_behaves_like 'empty wiki message', issuable: true, expect_button: true
      end
    end
  end
end
