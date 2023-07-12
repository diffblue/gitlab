# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnersFinder, feature_category: :runner_fleet do
  describe '#execute' do
    subject(:execute) do
      described_class.new(current_user: user, params: params).execute
    end

    context 'when sorting' do
      let(:params) { { sort: sort_key } }

      context 'with sort param equal to most_active_desc' do
        let_it_be(:runners) { create_list(:ci_runner, 6) }
        let_it_be(:project) { create(:project) }

        let(:sort_key) { 'most_active_desc' }

        before_all do
          runners.map.with_index do |runner, number_of_builds|
            create_list(:ci_build, number_of_builds, runner: runner, project: project).each do |build|
              create(:ci_running_build, runner: build.runner, build: build, project: project)
            end
          end
        end

        context 'when admin', :enable_admin_mode do
          let_it_be(:admin) { create(:user, :admin) }

          let(:user) { admin }

          it 'returns runners with the most running builds' do
            is_expected.to eq(runners[1..5].reverse)
          end
        end

        context 'with user as group owner' do
          let_it_be(:group) { create(:group) }
          let_it_be(:user) { create(:user) }

          before_all do
            group.add_owner(user)
          end

          context 'with sort param set to most_active_desc' do
            let(:params) do
              { group: group, sort: 'most_active_desc' }
            end

            it 'raises an error' do
              expect { execute }.to raise_error(ArgumentError, 'most_active_desc can only be used on instance runners')
            end
          end
        end
      end
    end
  end
end
