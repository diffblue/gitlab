# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ai::Action, feature_category: :not_owned do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }
  let_it_be(:resource, reload: true) { create(:issue) }
  let(:resource_id) { resource.to_gid.to_s }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#ready?' do
    let(:arguments) { { summarize_comments: { resource_id: resource_id } } }

    it { is_expected.to be_ready(**arguments) }

    context 'when no arguments are set' do
      let(:arguments) { {} }

      it 'raises error' do
        expect { subject.ready?(**arguments) }
          .to raise_error(
            Gitlab::Graphql::Errors::ArgumentError,
            described_class::MUTUALLY_EXCLUSIVE_ARGUMENTS_ERROR
          )
      end
    end
  end

  describe '#resolve' do
    subject do
      mutation.resolve(**input)
    end

    shared_examples_for 'an AI action' do
      context 'when resource_id is not for an Ai::Model' do
        let(:resource_id) { "gid://gitlab/Note/#{resource.id}" }

        it 'raises error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
        end
      end

      context 'when resource cannot be found' do
        let(:resource_id) { "gid://gitlab/Issue/#{non_existing_record_id}" }

        it 'raises error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when the action is called too many times' do
        it 'raises error' do
          expect(Gitlab::ApplicationRateLimiter).to(
            receive(:throttled?).with(:ai_action, scope: [user]).and_return(true)
          )

          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, /too many times/)
        end
      end

      context 'when user cannot read resource' do
        it 'raises error' do
          allow(Ability)
            .to receive(:allowed?)
            .with(user, "read_#{resource.to_ability_name}", resource)
            .and_return(false)

          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when user is allowed to read resource but is not a member' do
        it 'raises error' do
          allow(Ability)
            .to receive(:allowed?)
            .with(user, "read_#{resource.to_ability_name}", resource)
            .and_return(true)

          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when the user can perform AI action' do
        before do
          resource.project.add_developer(user)
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(openai_experimentation: false)
          end

          it 'raises error' do
            expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        it 'calls Llm::ExecuteMethodService' do
          expect_next_instance_of(
            Llm::ExecuteMethodService,
            user,
            resource,
            expected_method,
            expected_options
          ) do |svc|
            expect(svc)
              .to receive(:execute)
              .and_return(
                instance_double(ServiceResponse, success?: true)
              )
          end

          expect(subject[:errors]).to be_empty
        end

        context 'when Llm::ExecuteMethodService errors out' do
          it 'returns errors' do
            expect_next_instance_of(
              Llm::ExecuteMethodService,
              user,
              resource,
              expected_method,
              expected_options
            ) do |svc|
              expect(svc)
                .to receive(:execute)
                .and_return(
                  instance_double(ServiceResponse, success?: false, message: 'error')
                )
            end

            expect(subject[:errors]).to eq(['error'])
          end
        end
      end
    end

    context 'when summarize_comments input is set' do
      let(:input) { { summarize_comments: { resource_id: resource_id } } }
      let(:expected_method) { :summarize_comments }
      let(:expected_options) { {} }

      it_behaves_like 'an AI action'
    end
  end
end
