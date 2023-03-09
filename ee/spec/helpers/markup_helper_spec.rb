# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MarkupHelper do
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:user) do
    user = create(:user, username: 'gfm')
    project.add_maintainer(user)
    user
  end

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#render_wiki_content' do
    subject { helper.render_wiki_content(wiki_page) }

    context 'when file is Markdown' do
      context 'when content has labels' do
        let(:wiki_page) { create(:wiki_page, format: :markdown, container: container, title: 'merge', content: '~Bug') }
        let(:wiki) { wiki_page.wiki }

        before do
          allow(helper).to receive(:current_user).and_return(nil)

          helper.instance_variable_set(:@wiki, wiki)
        end

        shared_examples 'renders label' do
          specify do
            result = subject
            doc = Nokogiri::HTML.parse(result)

            expect(doc.css('.gl-label-link')).not_to be_empty
          end
        end

        context 'when wiki is a group wiki' do
          let_it_be(:group) { create(:group) }
          let_it_be(:label) { create(:group_label, group: group, title: 'Bug') }

          let(:container) { group }

          it_behaves_like 'renders label'
        end

        context 'when wiki is a project wiki' do
          let_it_be(:label) { create(:label, title: 'Bug', project: project) }

          let(:container) { project }

          it_behaves_like 'renders label'
        end
      end
    end
  end
end
