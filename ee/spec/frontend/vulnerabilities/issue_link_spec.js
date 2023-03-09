import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import IssueLink from 'ee/vulnerabilities/components/issue_link.vue';
import { getBinding, createMockDirective } from 'helpers/vue_mock_directive';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('IssueLink component', () => {
  let wrapper;

  const createIssue = (options) => ({
    title: 'my-issue',
    iid: 12,
    webUrl: 'http://localhost/issues/~/12',
    ...options,
  });

  const createWrapper = ({ propsData }) => {
    return extendedWrapper(
      shallowMount(IssueLink, {
        propsData,
        directives: {
          GlTooltip: createMockDirective('gl-tooltip'),
        },
        // this allows us to retrieve the rendered text
        stubs: { GlSprintf },
      }),
    );
  };

  const findIssueLink = () => wrapper.findComponent(GlLink);
  const findIcon = () => wrapper.findComponent(GlIcon);

  describe.each([true, false])('internal and Jira issues with "isJira" set to "%s"', (isJira) => {
    const issue = createIssue();

    beforeEach(() => {
      wrapper = createWrapper({ propsData: { issue, isJira } });
    });

    it('should contain a link to the issue', () => {
      expect(findIssueLink().attributes('href')).toBe(issue.webUrl);
    });

    it('should contain the title', () => {
      const tooltip = getBinding(findIssueLink().element, 'gl-tooltip');
      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe(issue.title);
    });
  });

  describe('internal issues', () => {
    describe.each`
      state       | icon              | shouldContainClosedText
      ${'opened'} | ${'issues'}       | ${false}
      ${'closed'} | ${'issue-closed'} | ${true}
    `('with state "$state"', ({ state, icon, shouldContainClosedText }) => {
      beforeEach(() => {
        wrapper = createWrapper({ propsData: { issue: createIssue({ state }) } });
      });

      it('should contain the correct issue icon', () => {
        expect(findIcon().attributes('name')).toBe(icon);
      });

      it(`${
        shouldContainClosedText ? 'should' : 'should not'
      } contain a text that marks it as closed`, () => {
        expect(findIssueLink().text().includes('closed')).toBe(shouldContainClosedText);
      });
    });
  });

  describe('Jira issues', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        propsData: { issue: createIssue(), isJira: true },
      });
    });

    it('should contain a Jira logo icon', () => {
      expect(wrapper.findByTestId('jira-logo').exists()).toBe(true);
    });

    it('should contain an external-link icon', () => {
      expect(findIcon().attributes('name')).toBe('external-link');
    });
  });
});
