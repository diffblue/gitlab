# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::LearnGitlab, feature_category: :onboarding do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:learn_gitlab_project) { create(:project, name: described_class::PROJECT_NAME) }
  let_it_be(:learn_gitlab_board) { create(:board, project: learn_gitlab_project, name: described_class::BOARD_NAME) }
  let_it_be(:learn_gitlab_label) { create(:label, project: learn_gitlab_project, name: described_class::LABEL_NAME) }

  before do
    learn_gitlab_project.add_developer(current_user)
  end

  describe '#project' do
    subject { described_class.new(current_user).project }

    it { is_expected.to eq learn_gitlab_project }

    context 'when it is created during trial signup' do
      let_it_be(:learn_gitlab_project) do
        create(:project, name: described_class::PROJECT_NAME_ULTIMATE_TRIAL, path: 'learn-gitlab-ultimate-trial')
      end

      it { is_expected.to eq learn_gitlab_project }
    end
  end

  describe '#board' do
    subject { described_class.new(current_user).board }

    it { is_expected.to eq learn_gitlab_board }
  end

  describe '#label' do
    subject { described_class.new(current_user).label }

    it { is_expected.to eq learn_gitlab_label }
  end

  describe '#onboarding_and_available?' do
    using RSpec::Parameterized::TableSyntax

    let(:namespace) { build(:namespace) }

    where(:current_user, :project, :available, :onboarding, :expected_result) do
      nil  | nil  | false | false | false
      true | nil  | false | false | false
      true | true | false | false | false
      true | true | true  | false | false
      true | true | true  | true  | true
      nil  | nil  | false | true  | false
      nil  | nil  | true  | true  | false
      nil  | nil  | true  | false | false
      nil  | true | true  | true  | false
      nil  | true | true  | false | false
      nil  | true | false | false | false
      nil  | true | false | true  | false
      true | nil  | true  | true  | false
      true | true | false | true  | false
      true | nil  | true  | false | false
      true | nil  | false | true  | false
    end

    with_them do
      before do
        allow_next_instance_of(described_class) do |learn_gitlab|
          allow(learn_gitlab).to receive(:project).and_return(project)
          allow(learn_gitlab).to receive(:available?).and_return(available)
          allow(learn_gitlab).to receive(:current_user).and_return(current_user)
        end

        allow(Onboarding::Progress).to receive(:onboarding?).with(namespace).and_return(onboarding)
      end

      subject { described_class.new(current_user).onboarding_and_available?(namespace) }

      it { is_expected.to be expected_result }
    end
  end
end
