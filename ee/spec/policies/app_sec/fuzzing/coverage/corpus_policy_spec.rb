# frozen_string_literal: true
require 'spec_helper'

RSpec.describe AppSec::Fuzzing::Coverage::CorpusPolicy do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  let_it_be(:corpus) { create(:corpus, project: project) }

  subject { described_class.new(user, corpus) }

  before do
    stub_licensed_features(coverage_fuzzing: true)
  end

  describe 'coverage_fuzzing policies' do
    let(:policies) { [:read_coverage_fuzzing] }

    context 'when a user does not have access to the project' do
      it { is_expected.to be_disallowed(*policies) }
    end

    context 'when the user is a developer' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to be_allowed(*policies) }
    end

    context 'when the user is a guest' do
      before do
        project.add_guest(user)
      end

      it { is_expected.to be_disallowed(*policies) }
    end

    context 'when the user is a reporter' do
      before do
        project.add_reporter(user)
      end

      it { is_expected.to be_disallowed(*policies) }
    end

    context 'when the user is a developer' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to be_allowed(*policies) }
    end

    context 'when the user is a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { is_expected.to be_allowed(*policies) }
    end

    context 'when the user is an owner' do
      before do
        group.add_owner(user)
      end

      it { is_expected.to be_allowed(*policies) }
    end

    context 'when the user is allowed' do
      before do
        project.add_developer(user)
      end

      context 'coverage_fuzzing licensed feature is not available' do
        let(:project) { create(:project, group: group) }

        before do
          stub_licensed_features(coverage_fuzzing: false)
        end

        it { is_expected.to be_disallowed(*policies) }
      end
    end
  end
end
