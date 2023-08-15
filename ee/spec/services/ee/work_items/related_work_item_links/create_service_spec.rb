# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::RelatedWorkItemLinks::CreateService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project, namespace: namespace) }
    let_it_be(:work_item) { create(:work_item, project: project) }
    let_it_be(:reporter) { create(:user).tap { |u| project.add_reporter(u) } }
    let_it_be(:user) { reporter }
    let_it_be(:work_item_a) { create(:work_item, project: project) }
    let_it_be(:project2) { create(:project, namespace: project.namespace).tap { |p| p.add_reporter(reporter) } }
    let_it_be(:another_work_item) { create(:work_item, project: project2) }

    let(:link_class) { ::WorkItems::RelatedWorkItemLink }
    let(:params) { { target_issuable: [work_item_a, another_work_item] } }

    subject(:link_items) { described_class.new(work_item, user, params).execute }

    shared_examples 'successful response' do |link_type:|
      before do
        params[:link_type] = link_type
      end

      it 'creates relationships' do
        expect { link_items }.to change { link_class.count }.by(2)
      end

      it 'returns success status and created links', :aggregate_failures do
        expect(link_items.keys).to match_array([:status, :created_references, :message])
        expect(link_items[:status]).to eq(:success)
        expect(link_items[:created_references]).not_to be_empty
        expect(link_items[:message]).to eq("Successfully linked ID(s): #{work_item_a.id} and #{another_work_item.id}.")
      end
    end

    shared_examples 'error response' do |link_type:|
      before do
        params[:link_type] = link_type
      end

      it 'returns error' do
        is_expected.to eq(
          message: 'Blocked work items are not available for the current subscription tier',
          status: :error,
          http_status: 403
        )
      end

      it 'no relationship is created' do
        expect { link_items }.not_to change { link_class.count }
      end
    end

    context 'when licensed feature `blocked_work_items` is available' do
      before do
        stub_licensed_features(blocked_work_items: true)
      end

      it_behaves_like 'issuable link creation with blocking link_type' do
        let(:issuable_link_class) { link_class }
        let(:issuable) { work_item }
        let(:issuable2) { work_item_a }
        let(:issuable3) { another_work_item }
      end

      it_behaves_like 'successful response', link_type: 'blocks'
      it_behaves_like 'successful response', link_type: 'is_blocked_by'
    end

    context 'when licensed feature `blocked_work_items` is not available' do
      before do
        stub_licensed_features(blocked_work_items: false)
      end

      it_behaves_like 'error response', link_type: 'blocks'
      it_behaves_like 'error response', link_type: 'is_blocked_by'
    end
  end
end
