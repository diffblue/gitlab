# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::LearnGitlab, feature_category: :onboarding do
  using RSpec::Parameterized::TableSyntax

  describe '#available?' do
    let(:namespace) { instance_double(Namespace) }

    where(:user, :onboarding, :expected_result) do
      nil  | false  | false
      true | false  | false
      nil  | true   | false
      true | true   | true
    end

    with_them do
      before do
        allow(::Onboarding::Progress).to receive(:onboarding?).with(namespace).and_return(onboarding)
      end

      subject { described_class.available?(namespace, user) }

      it { is_expected.to be expected_result }
    end
  end
end
