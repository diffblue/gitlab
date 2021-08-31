# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Wiki' do
      describe 'Creating pages in Group Wikis' do
        let(:wiki_title) { 'New Wiki page' }
        let(:wiki_content) { 'New Wiki content' }

        before do
          Flow::Login.sign_in
        end

        context 'when Wiki is empty' do
          let(:group) { Resource::Group.fabricate_via_api! }

          it 'creates a home page', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1831' do
            group.visit!

            Page::Group::Menu.perform(&:click_group_wiki_link)
            EE::Page::Group::Wiki::Show.perform(&:click_create_your_first_page)

            EE::Page::Group::Wiki::Edit.perform do |edit|
              edit.set_title(wiki_title)
              edit.set_content(wiki_content)
              edit.click_submit
            end

            EE::Page::Group::Wiki::Show.perform do |wiki|
              expect(wiki).to have_title(wiki_title)
              expect(wiki).to have_content(wiki_content)
            end
          end
        end

        context 'when Wiki has a home page' do
          let(:wiki) do
            Resource::Wiki::GroupPage.fabricate_via_api! do |wiki|
              wiki.title = 'Home page'
            end
          end

          it 'adds a second page', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1827' do
            wiki.visit!

            EE::Page::Group::Wiki::Show.perform(&:click_new_page)

            EE::Page::Group::Wiki::Edit.perform do |edit|
              edit.set_title(wiki_title)
              edit.set_content(wiki_content)
              edit.click_submit
            end

            EE::Page::Group::Wiki::Show.perform do |wiki|
              expect(wiki).to have_title(wiki_title)
              expect(wiki).to have_content(wiki_content)
              expect(wiki).to have_page_listed('Home page')
            end
          end
        end
      end
    end
  end
end
