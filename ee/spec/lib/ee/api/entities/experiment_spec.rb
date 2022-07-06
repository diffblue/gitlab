# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::API::Entities::Experiment do
  let(:experiment) { Feature::Definition.get(:null_hypothesis) }
  let(:entity) { described_class.new(experiment) }

  subject { entity.as_json }

  it do
    is_expected.to match(
      key: "null_hypothesis",
      definition: {
        name: 'null_hypothesis',
        introduced_by_url: 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45840',
        rollout_issue_url: nil,
        milestone: '13.7',
        type: 'experiment',
        group: 'group::acquisition',
        default_enabled: false,
        log_state_changes: nil
      },
      current_status: {
        state: :off,
        gates: [
          {
            key: :boolean,
            value: false
          }
        ]
      }
    )
  end

  it "understands conditional state and what that means" do
    Feature.enable_percentage_of_time(:null_hypothesis, 1)

    expect(subject[:current_status]).to match({
                                                state: :conditional,
                                                gates: [
                                                  {
                                                    key: :boolean,
                                                    value: false
                                                  },
                                                  {
                                                    key: :percentage_of_time,
                                                    value: 1
                                                  }
                                                ]
                                              })
  end

  it "understands state and what that means for if its enabled or not" do
    Feature.enable_percentage_of_time(:null_hypothesis, 100)

    expect(subject[:current_status]).to match({
                                                state: :on,
                                                gates: [
                                                  {
                                                    key: :boolean,
                                                    value: false
                                                  },
                                                  {
                                                    key: :percentage_of_time,
                                                    value: 100
                                                  }
                                                ]
                                              })
  end

  it "truncates the name since some experiments include extra data in their feature flag name" do
    allow(experiment).to receive(:attributes).and_return({ name: 'foo_experiment_percentage' })

    expect(subject).to include(
      key: 'foo'
    )
  end
end
