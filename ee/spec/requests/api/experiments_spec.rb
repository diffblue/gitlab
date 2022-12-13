# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Experiments, feature_category: :experimentation_expansion do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, name: 'GitLab.com', path: 'gitlab-com') }

  let(:definition_yaml) { Rails.root.join('config', 'feature_flags', 'experiment', 'null_hypothesis.yml') }

  describe 'GET /experiments' do
    context 'when on .com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
        stub_experiments(null_hypothesis: :candidate)

        definition = YAML.load_file(definition_yaml).deep_symbolize_keys!
        allow(Feature::Definition.definitions).to receive(:values).and_return(
          [
            Feature::Definition.new(definition_yaml.to_s, definition),
            Feature::Definition.new(
              'foo/non_experiment.yml',
              definition.merge(type: 'development', name: 'non_experiment')
            )
          ])
      end

      it 'returns a 401 for anonymous users' do
        get api('/experiments')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns a 403 for users' do
        get api('/experiments', user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns a 403 for non human users' do
        bot = create(:user, :bot)
        group.add_developer(bot)

        get api('/experiments', bot)

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      context 'for gitlab team members' do
        before do
          group.add_developer(user)
        end

        it 'returns the feature flag details', :aggregate_failures do
          get api('/experiments', user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include({
            key: 'null_hypothesis',
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
          }.as_json)
        end

        it 'understands the state of the feature flag and what that means for an experiment', :aggregate_failures do
          Feature.enable_percentage_of_actors(:null_hypothesis, 1)

          get api('/experiments', user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include(hash_including({
            key: 'null_hypothesis',
            current_status: {
              state: :conditional,
              gates: [
                {
                  key: :boolean,
                  value: false
                },
                {
                  key: :percentage_of_actors,
                  value: 1
                }
              ]
            }
          }.as_json))
        end

        describe 'the null_hypothesis as a canary' do
          # This group of test ensures that we will continue to have a functional
          # backend experiment. It's part of the suite of tooling that's in place to
          # ensure that we don't change notable aspects of experimentation, like
          # the position of the contexts etc.
          #
          # We wrap our experiments endpoint in a canary like experiment that if
          # broken will render this endpoint visibly broken.
          #
          # This is something of an integration level and shouldn't be adjusted
          # without proper consultation with the relevant Growth teams.

          it 'runs and tracks the expected events' do
            contexts = []

            # Yes, we really do want to test this and the only way to get here
            # is by calling a private method.
            expect(Gitlab::Tracking.send(:tracker)).to receive(:event).with(
              'null_hypothesis',
              'assignment',
              label: nil,
              property: nil,
              value: nil,
              context: [
                instance_of(SnowplowTracker::SelfDescribingJson),
                instance_of(SnowplowTracker::SelfDescribingJson)
              ]
            ) { |_, _, **options| contexts = options[:context] }

            get api('/experiments', user)

            # Ensure the order of the contexts stays correct for now.
            #
            # If you change this, you need to talk with the growth team,
            # because some reporting is done (incorrectly) based on the index
            # of this context.
            expect(contexts[1].to_json).to include({
              schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/1-0-0',
              data: {
                experiment: 'null_hypothesis',
                key: anything,
                variant: 'candidate'
              }
            })
          end

          it 'returns a 400 if experimentation seems broken', :aggregate_failures do
            # we assume that rendering control would only be done in error.
            stub_experiments(null_hypothesis: :control)

            get api('/experiments', user)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response).to eq({
              message: '400 Bad request - experimentation may not be working right now'
            }.as_json)
          end

          it 'publishes into a collection of experiments that have been run in the request' do
            expect(RequestStore).to receive(:clear!).and_wrap_original do |clear|
              expect(ApplicationExperiment.published_experiments['null_hypothesis']).to include(
                excluded: false,
                experiment: 'null_hypothesis',
                variant: 'candidate'
              )

              clear.call
            end

            get api('/experiments', user)
          end
        end
      end
    end

    context 'when not .com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'returns a 403 for users' do
        group.add_developer(user)

        get api('/experiments', user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
