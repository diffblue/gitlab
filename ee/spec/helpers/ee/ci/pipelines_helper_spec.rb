# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Ci::PipelinesHelper do
  describe '#show_cc_validation_alert?' do
    using RSpec::Parameterized::TableSyntax

    subject(:show_cc_validation_alert?) { helper.show_cc_validation_alert?(pipeline) }

    let(:current_user) { instance_double(User) }
    let(:project) { instance_double(Project) }
    let(:pipeline) { instance_double(Ci::Pipeline, user_not_verified?: user_not_verified?, project: project, user: current_user) }

    where(:user_not_verified?, :has_required_cc?, :result) do
      true                   | false            | true
      false                  | true             | false
      true                   | true             | false
      false                  | false            | false
    end

    with_them do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
        allow(helper).to receive(:current_user).and_return(current_user)
        allow(current_user).to receive(:has_required_credit_card_to_run_pipelines?)
                                 .with(project)
                                 .and_return(has_required_cc?)
      end

      it { is_expected.to eq(result) }
    end

    context 'without current user' do
      let(:pipeline) { instance_double(Ci::Pipeline, user: nil) }

      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it { is_expected.to be_falsy }
    end

    context 'when not in dev env or com' do
      let(:pipeline) { instance_double(Ci::Pipeline) }

      before do
        allow(Gitlab).to receive(:com?) { false }
      end

      it { is_expected.to be_falsy }
    end
  end
end
