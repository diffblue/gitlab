# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', product_group: :knowledge do
    describe 'Creating pages in group wikis' do
      let(:wiki_title) { 'New Wiki page' }
      let(:wiki_content) { 'New Wiki content' }

      before do
        Flow::Login.sign_in
      end

      context 'when wiki is empty' do
        let(:group) { Resource::Group.fabricate_via_api! }

        it 'creates a new page', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347689' do
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

      context 'when wiki has a home page' do
        let(:wiki) do
          Resource::Wiki::GroupPage.fabricate_via_api!
        end

        it 'adds a second page', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347693' do
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
            expect(wiki).to have_page_listed('Home')
          end
        end
      end
    end
  end
end
