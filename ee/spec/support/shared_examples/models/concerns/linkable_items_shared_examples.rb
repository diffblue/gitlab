# frozen_string_literal: true

RSpec.shared_examples 'includes LinkableItem concern (EE)' do
  context 'for callbacks' do
    let_it_be(:project) { create(:project) }
    let_it_be(:target) { create(item_factory) } # rubocop:disable Rails/SaveBang
    let_it_be(:source) { create(item_factory) } # rubocop:disable Rails/SaveBang

    describe '.after_create_commit' do
      context 'with TYPE_BLOCKS relation' do
        it 'updates blocking issues count' do
          expect(source).to receive(:update_blocking_issues_count!)
          expect(target).not_to receive(:update_blocking_issues_count!)

          create(link_factory, target: target, source: source, link_type: link_class::TYPE_BLOCKS)
        end
      end

      context 'with TYPE_RELATES_TO' do
        it 'does not update blocking_issues_count' do
          expect(source).not_to receive(:update_blocking_issues_count!)
          expect(target).not_to receive(:update_blocking_issues_count!)

          create(link_factory, target: target, source: source, link_type: link_class::TYPE_RELATES_TO)
        end
      end
    end

    describe '.after_destroy_commit' do
      context 'with TYPE_BLOCKS relation' do
        it 'updates blocking issues count' do
          link = create(link_factory, target: target, source: source, link_type: link_class::TYPE_BLOCKS)

          expect(source).to receive(:update_blocking_issues_count!)
          expect(target).not_to receive(:update_blocking_issues_count!)

          link.destroy!
        end
      end

      context 'with TYPE_RELATES_TO' do
        it 'does not update blocking_issues_count' do
          link = create(link_factory, target: target, source: source, link_type: link_class::TYPE_RELATES_TO)

          expect(source).not_to receive(:update_blocking_issues_count!)
          expect(target).not_to receive(:update_blocking_issues_count!)

          link.destroy!
        end
      end
    end
  end

  it_behaves_like 'issuables that can block or be blocked' do
    def factory_class
      :issue_link
    end

    let(:issuable_type) { :issue }

    let_it_be(:blocked_issuable_1) { create(item_factory) } # rubocop:disable Rails/SaveBang
    let_it_be(:project) { blocked_issuable_1.project }
    let_it_be(:blocked_issuable_2) { create(item_factory, project: project) }
    let_it_be(:blocked_issuable_3) { create(item_factory, project: project) }
    let_it_be(:blocking_issuable_1) { create(item_factory, project: project) }
    let_it_be(:blocking_issuable_2) { create(item_factory, project: project) }
  end
end
