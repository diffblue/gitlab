# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epic::RelatedEpicLink do
  describe 'validations' do
    describe '#validate_max_epic_relations' do
      let_it_be(:source) { create(:epic) }
      let_it_be(:target) { create(:epic) }
      let_it_be(:link) { create(:related_epic_link, source: source, target: target) }

      let(:source_link) { build(:related_epic_link, source: source) }
      let(:target_link) { build(:related_epic_link, target: target) }

      it 'is valid' do
        expect(source_link).to be_valid
        expect(target_link).to be_valid
      end

      context 'when existing related epics reached limit' do
        before do
          stub_const('Epic::RelatedEpicLink::MAX_EPIC_RELATIONS', 1)
        end

        it 'is not valid' do
          expect(source_link).not_to be_valid
          expect(target_link).not_to be_valid
        end
      end
    end
  end

  it_behaves_like 'issuable link' do
    let_it_be_with_reload(:issuable_link) { create(:related_epic_link) }
    let_it_be(:issuable) { create(:epic) }
    let(:issuable_class) { 'Epic' }
    let(:issuable_link_factory) { :related_epic_link }
  end

  it_behaves_like 'issuables that can block or be blocked' do
    def factory_class
      :related_epic_link
    end

    let(:issuable_type) { :epic }

    let_it_be(:blocked_issuable_1) { create(:epic) }
    let_it_be(:blocked_issuable_2) { create(:epic) }
    let_it_be(:blocked_issuable_3) { create(:epic) }
    let_it_be(:blocking_issuable_1) { create(:epic) }
    let_it_be(:blocking_issuable_2) { create(:epic) }
  end
end
