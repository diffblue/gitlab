# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::SecurityTrainingUrlsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    before do
      stub_licensed_features(security_dashboard: true)
    end

    subject { resolve(described_class, obj: project, ctx: { current_user: user }) }

    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    context 'when the user is not authorized' do
      it 'does not do the resolver action' do
        expect(subject).to be_nil
      end
    end

    context 'when the user is authorized' do
      before do
        project.add_developer(user)
      end

      it 'calls TrainingUrlsFinder#execute' do
        expect_next_instance_of(::Security::TrainingUrlsFinder) do |finder|
          expect(finder).to receive(:execute)
        end

        subject
      end
    end
  end
end
