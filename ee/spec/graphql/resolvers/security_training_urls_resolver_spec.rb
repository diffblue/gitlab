# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::SecurityTrainingUrlsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    subject { resolve(described_class, obj: project) }

    let_it_be(:project) { create(:project) }

    it 'calls TrainingUrlsFinder#execute' do
      expect_next_instance_of(::Security::TrainingUrlsFinder) do |finder|
        expect(finder).to receive(:execute)
      end

      subject
    end
  end
end
