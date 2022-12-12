# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Runner::Update, feature_category: :runner_fleet do
  include GraphqlHelpers

  describe '#resolve' do
    let(:runner) do
      create(:ci_runner,
             active: true, locked: false, run_untagged: true,
             public_projects_minutes_cost_factor: 0.0, private_projects_minutes_cost_factor: 0.0)
    end

    let(:mutation) { described_class.new(object: nil, context: current_ctx, field: nil) }

    subject(:mutation_result) { mutation.resolve(id: runner.to_global_id, **mutation_params) }

    def resolve
      mutation_result
      runner.reload
    end

    context 'when user can update runner', :enable_admin_mode do
      let(:admin_user) { create(:user, :admin) }
      let(:current_ctx) { { current_user: admin_user } }

      context 'when mutation includes cost factor arguments' do
        let(:mutation_params) do
          {
            public_projects_minutes_cost_factor: 2.5,
            private_projects_minutes_cost_factor: 0.5
          }
        end

        it 'updates cost factors to specified values', :aggregate_failures do
          expect { resolve }
            .to change { runner.public_projects_minutes_cost_factor }.from(0).to(2.5)
            .and change { runner.private_projects_minutes_cost_factor }.from(0).to(0.5)
        end
      end
    end
  end
end
