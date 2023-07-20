# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin Runners", feature_category: :runner_fleet do
  include RunnerReleasesHelper
  include Features::RunnersHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)

    wait_for_requests
  end

  describe "Admin Runners page", :js do
    context "with a GitLab version and runner releases" do
      let_it_be(:runner) { create(:ci_runner, :instance, version: '15.0.0') }
      let_it_be(:runner_manager) { create(:ci_runner_machine, runner: runner, version: '15.0.0') }

      let(:upgrade_status) { :unavailable }
      let!(:runner_version) { create(:ci_runner_version, version: '15.0.0', status: upgrade_status) }

      shared_examples 'upgrade is recommended' do
        it 'shows an orange upgrade recommended icon' do
          within_runner_row(runner.id) do
            expect(page).to have_selector '.gl-text-orange-500[data-testid="upgrade-icon"]'
          end
        end
      end

      shared_examples 'upgrade is available' do
        it 'shows a blue upgrade available icon' do
          within_runner_row(runner.id) do
            expect(page).to have_selector '.gl-text-blue-500[data-testid="upgrade-icon"]'
          end
        end
      end

      shared_examples 'no upgrade shown' do
        it 'shows no upgrade icon' do
          within_runner_row(runner.id) do
            expect(page).not_to have_selector '[data-testid="upgrade-icon"]'
          end
        end
      end

      context 'with runner_upgrade_management enabled' do
        before do
          stub_licensed_features(runner_upgrade_management: true)

          visit admin_runners_path
        end

        describe 'recommended to upgrade' do
          let(:upgrade_status) { :recommended }

          it_behaves_like 'upgrade is recommended'

          context 'when filtering "up to date"' do
            before do
              input_filtered_search_filter_is_only(s_('Runners|Upgrade Status'), s_('Runners|Up to date'))
            end

            it_behaves_like 'shows no runners found'
          end
        end

        describe 'available to upgrade' do
          let(:upgrade_status) { :available }

          it_behaves_like 'upgrade is available'
        end

        describe 'no upgrade available' do
          let(:upgrade_status) { :unavailable }

          it_behaves_like 'no upgrade shown'
        end
      end

      shared_examples 'runner upgrade disabled' do
        describe 'filters' do
          let(:upgrade_status) { :unavailable }

          it 'does not show upgrade filter' do
            focus_filtered_search

            page.within(search_bar_selector) do
              expect(page).not_to have_link(s_('Runners|Upgrade Status'))
            end
          end
        end

        describe 'can upgrade' do
          let(:upgrade_status) { :available }

          it_behaves_like 'no upgrade shown'
        end
      end

      context 'with runner_upgrade_management licensed feature is disabled' do
        before do
          stub_licensed_features(runner_upgrade_management: false)

          visit admin_runners_path
        end

        it_behaves_like 'runner upgrade disabled'
      end

      context 'when fetching runner releases setting is disabled' do
        before do
          stub_application_setting(update_runner_versions_enabled: false)

          visit admin_runners_path
        end

        it_behaves_like 'runner upgrade disabled'
      end
    end
  end

  describe "Runner edit page", :js do
    let_it_be(:project) { create(:project) }
    let_it_be(:instance_runner) { create(:ci_runner, :instance) }
    let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project]) }

    shared_examples 'shows populated cost factor' do
      it 'shows cost factor fields' do
        expect(page).to have_field(_('Public projects compute cost factor'), with: '1')
        expect(page).to have_field(_('Private projects compute cost factor'), with: '1')
      end

      it 'submits correctly' do
        click_on _('Save changes')

        expect(page).to have_content(_('Changes saved.'))
      end
    end

    shared_examples 'does not show cost factor' do
      it 'does not show cost factor fields' do
        expect(page).not_to have_field(_('Public projects compute cost factor'))
        expect(page).not_to have_field(_('Private projects compute cost factor'))
      end

      it 'submits correctly' do
        click_on _('Save changes')

        expect(page).to have_content(_('Changes saved.'))
      end
    end

    before do
      allow(Gitlab).to receive(:com?).and_return(dot_com)
      visit edit_admin_runner_path(runner)
    end

    context 'when Gitlab.com?' do
      let(:dot_com) { true }

      context 'when editing an instance runner' do
        let(:runner) { instance_runner }

        it_behaves_like 'shows populated cost factor'
      end

      context 'when editing a project runner' do
        let(:runner) { project_runner }

        it_behaves_like 'does not show cost factor'
      end
    end

    context 'when not Gitlab.com?' do
      let(:dot_com) { false }

      context 'when editing an instance runner' do
        let(:runner) { instance_runner }

        it_behaves_like 'does not show cost factor'
      end

      context 'when editing a project runner' do
        let(:runner) { project_runner }

        it_behaves_like 'does not show cost factor'
      end
    end
  end
end
