# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin Runners", feature_category: :runner_fleet do
  include RunnerReleasesHelper
  include Spec::Support::Helpers::Features::RunnersHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)

    wait_for_requests
  end

  describe "Admin Runners page", :js do
    context "with a GitLab version and runner releases" do
      let!(:runner) { create(:ci_runner, :instance, version: runner_version) }

      before do
        stub_runner_releases(available_runner_releases, gitlab_version: '15.1.0')
      end

      shared_examples 'upgrade is recommended' do
        it 'shows upgrade recommended badge' do
          within_runner_row(runner.id) do
            expect(page).to have_selector '.badge', text: s_('Runners|Upgrade recommended')
          end
        end
      end

      shared_examples 'upgrade is available' do
        it 'shows upgrade available badge' do
          within_runner_row(runner.id) do
            expect(page).to have_selector '.badge', text: s_('Runners|Upgrade available')
          end
        end
      end

      shared_examples 'no upgrade shown' do
        it 'shows no upgrade badge' do
          within_runner_row(runner.id) do
            expect(page).not_to have_selector '.badge', text: s_('Runners|Upgrade recommended')
            expect(page).not_to have_selector '.badge', text: s_('Runners|Upgrade available')
          end
        end
      end

      context 'with runner_upgrade_management enabled' do
        before do
          stub_licensed_features(runner_upgrade_management: true)

          visit admin_runners_path
        end

        describe 'filters' do
          let(:runner_version) { '15.0.0' }
          let(:available_runner_releases) { %w[15.0.0] }

          it 'shows upgrade filter' do
            focus_filtered_search

            page.within(search_bar_selector) do
              expect(page).to have_link(s_('Runners|Upgrade Status'))
            end
          end
        end

        describe 'recommended to upgrade (patch)' do
          let(:runner_version) { '15.0.0' }
          let(:available_runner_releases) { %w[15.0.1] }

          it_behaves_like 'upgrade is recommended'
        end

        describe 'available to upgrade (minor)' do
          let(:runner_version) { '15.0.0' }
          let(:available_runner_releases) { %w[15.1.0] }

          it_behaves_like 'upgrade is available'
        end

        describe 'available to upgrade (major)' do
          let(:runner_version) { '14.0.0' }
          let(:available_runner_releases) { %w[15.1.0] }

          it_behaves_like 'upgrade is available'
        end

        describe 'no upgrade available' do
          let(:runner_version) { '15.0.0' }
          let(:available_runner_releases) { %w[15.0.0] }

          it_behaves_like 'no upgrade shown'
        end
      end

      context 'with runner_upgrade_management disabled' do
        before do
          stub_licensed_features(runner_upgrade_management: false)

          visit admin_runners_path
        end

        describe 'filters' do
          let(:runner_version) { '15.0.0' }
          let(:available_runner_releases) { %w[15.0.0] }

          it 'does not show upgrade filter' do
            focus_filtered_search

            page.within(search_bar_selector) do
              expect(page).not_to have_link(s_('Runners|Upgrade Status'))
            end
          end
        end

        describe 'can upgrade' do
          let(:runner_version) { '15.0.0' }
          let(:available_runner_releases) { %w[15.0.0 15.0.1 15.1.0] }

          it_behaves_like 'no upgrade shown'
        end
      end
    end
  end
end
