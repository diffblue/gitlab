# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::AnalyticsMenu do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, current_ref: project.repository.root_ref) }

  subject { described_class.new(context) }

  describe 'Menu items' do
    subject { described_class.new(context).renderable_items.index { |e| e.item_id == item_id } }

    describe 'Code Review' do
      let(:item_id) { :code_review }

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Insights' do
      let(:item_id) { :insights }
      let(:insights_available) { true }

      before do
        allow(project).to receive(:insights_available?).and_return(insights_available)
      end

      specify { is_expected.not_to be_nil }

      context 'when insights are not available' do
        let(:insights_available) { false }

        specify { is_expected.to be_nil }
      end

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Issue' do
      let(:item_id) { :issues }
      let(:licensed) { true }

      before do
        stub_licensed_features(issues_analytics: licensed)
      end

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end

      describe 'when licensed feature issues analytics is not enabled' do
        let(:licensed) { false }

        specify { is_expected.to be_nil }
      end
    end

    describe 'Merge Request' do
      let(:item_id) { :merge_requests }

      specify { is_expected.not_to be_nil }

      describe 'when the user does not have access' do
        let(:user) { nil }

        specify { is_expected.to be_nil }
      end
    end
  end
end
