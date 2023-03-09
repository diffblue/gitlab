import { shallowMount } from '@vue/test-utils';
import IssueCardWeight from 'ee/boards/components/issue_card_weight.vue';

function mountIssueCardWeight(propsData) {
  return shallowMount(IssueCardWeight, {
    propsData,
  });
}

describe('IssueCardWeight', () => {
  let wrapper;

  describe('weight text', () => {
    it('shows 0 when weight is 0', () => {
      wrapper = mountIssueCardWeight({
        weight: 0,
      });

      expect(wrapper.find('.board-card-info-text').text()).toContain('0');
    });

    it('shows 5 when weight is 5', () => {
      wrapper = mountIssueCardWeight({
        weight: 5,
      });

      expect(wrapper.find('.board-card-info-text').text()).toContain('5');
    });
  });

  it('renders a link when no tag is specified', () => {
    wrapper = mountIssueCardWeight({
      weight: 2,
    });

    expect(wrapper.find('span.board-card-info').exists()).toBe(false);
    expect(wrapper.find('a.board-card-info').exists()).toBe(true);
  });

  it('renders the tag when it is explicitly specified', () => {
    wrapper = mountIssueCardWeight({
      weight: 2,
      tagName: 'span',
    });

    expect(wrapper.find('span.board-card-info').exists()).toBe(true);
    expect(wrapper.find('a.board-card-info').exists()).toBe(false);
  });
});
