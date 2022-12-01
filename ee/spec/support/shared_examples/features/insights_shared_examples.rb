# frozen_string_literal: true

RSpec.shared_examples 'Insights page' do
  let_it_be(:user) { create(:user) }

  describe 'as a permitted user' do
    before_all do
      entity.add_maintainer(user)
    end

    before do
      sign_in(user)
    end

    context 'with correct license' do
      before do
        stub_licensed_features(insights: true)
      end

      it 'has correct title' do
        visit route

        expect(page).to have_gitlab_http_status(:ok)
        expect(page).to have_content('Insights')
      end

      context 'navigation' do
        let(:config) { entity.insights_config }
        let(:default_tab_id) { config.each_key.first }
        let(:default_tab_title) { config[default_tab_id][:title] }
        let(:route) { path }

        before do
          visit route
          wait_for_requests
        end

        it 'by default loads the first page', :js do
          page.within(".insights-container") do
            expect(page).to have_content(default_tab_title)
          end
        end

        context 'hash fragment navigation' do
          let(:non_default_tab_id) { config.keys.last }
          let(:non_default_tab_title) { config[non_default_tab_id][:title] }
          let(:hash_fragment) { "#/#{non_default_tab_id}" }
          let(:route) { path + hash_fragment }

          it 'loads the correct page', :js do
            page.within(".insights-container") do
              expect(page).to have_content(non_default_tab_title)
              expect(page.find('.js-insights-dropdown')).to have_text non_default_tab_title
            end
          end
        end

        it 'displays correctly when navigating back to insights', :js do
          visit root_path

          page.evaluate_script('window.history.back()')

          page.within(".insights-container") do
            expect(page).to have_content(default_tab_title)
          end
        end
      end
    end

    context 'without correct license' do
      before do
        stub_licensed_features(insights: false)
      end

      it 'returns 404' do
        visit route

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
