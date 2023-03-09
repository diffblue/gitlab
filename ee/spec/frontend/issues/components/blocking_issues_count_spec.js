import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BlockingIssuesCount from 'ee/issues/components/blocking_issues_count.vue';

describe('BlockingIssuesCount component', () => {
  const iconName = 'issue-block';
  const tooltipText = 'Blocking issues';
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);

  const mountComponent = ({
    blockingIssuesCount = 1,
    hasBlockedIssuesFeature = true,
    isListItem = false,
  } = {}) =>
    shallowMount(BlockingIssuesCount, {
      propsData: { blockingIssuesCount, isListItem },
      provide: { hasBlockedIssuesFeature },
    });

  describe('with blocked_issues license', () => {
    describe('when blocking issues count is positive', () => {
      beforeEach(() => {
        wrapper = mountComponent({ blockingIssuesCount: 1 });
      });

      it('renders blocking issues count', () => {
        expect(wrapper.text()).toBe('1');
        expect(wrapper.attributes('title')).toBe(tooltipText);
        expect(findIcon().props('name')).toBe(iconName);
      });
    });

    describe.each([0, null])('when blocking issues count is %s', (i) => {
      beforeEach(() => {
        wrapper = mountComponent({ blockingIssuesCount: i });
      });

      it('does not render blocking issues', () => {
        expect(wrapper.text()).toBe('');
      });
    });

    describe('when element is a list item', () => {
      beforeEach(() => {
        wrapper = mountComponent({ isListItem: true });
      });

      it('renders as `li` element', () => {
        expect(wrapper.element.tagName).toBe('LI');
      });
    });
  });

  describe('without blocked_issues license', () => {
    beforeEach(() => {
      wrapper = mountComponent({ hasBlockedIssuesFeature: false });
    });

    it('does not render blocking issues', () => {
      expect(wrapper.text()).toBe('');
    });
  });
});
