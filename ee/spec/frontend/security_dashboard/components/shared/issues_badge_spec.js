import { GlIcon, GlPopover, GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import IssuesBadge from 'ee/security_dashboard/components/shared/issues_badge.vue';
import IssueLink from 'ee/vulnerabilities/components/issue_link.vue';

describe('Remediated badge component', () => {
  const issues = [{ issue: { iid: 41 } }, { issue: { iid: 591 } }];

  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findIssueLinks = () => wrapper.findAllComponents(IssueLink);
  const findPopover = () => wrapper.findComponent(GlPopover);

  const createWrapper = ({ propsData }) => {
    return shallowMount(IssuesBadge, { propsData, stubs: { GlPopover, GlBadge } });
  };

  describe('when there are multiple issues', () => {
    beforeEach(() => {
      wrapper = createWrapper({ propsData: { issues, externalIssues: [] } });
    });

    it('displays the correct icon', () => {
      expect(findIcon().props('name')).toBe('issues');
    });

    it('links the badge and the popover', () => {
      const popover = wrapper.findComponent({ ref: 'popover' });
      expect(popover.props('target')()).toEqual(findIcon().element.parentNode);
    });

    it('displays the issues', () => {
      expect(findIssueLinks()).toHaveLength(issues.length);
    });

    it('displays the correct number of issues in the badge', () => {
      expect(findBadge().text()).toBe('2');
    });

    it('displays the correct number of issues in the popover title', () => {
      expect(findPopover().text()).toBe('2 Issues');
    });
  });

  describe('when there are no issues', () => {
    beforeEach(() => {
      wrapper = createWrapper({ propsData: { issues: [], externalIssues: [] } });
    });

    it('displays the correct number of issues in the badge', () => {
      expect(findBadge().text()).toBe('0');
    });

    it('displays the correct number of issues in the popover title', () => {
      expect(findPopover().text()).toBe('0 Issues');
    });
  });

  describe.each([true, false])('with "isJira" prop set to "%s"', (isJira) => {
    beforeEach(() => {
      wrapper = createWrapper({
        propsData: { issues, isJira },
      });
    });

    it('passes the correct prop to the issue link', () => {
      findIssueLinks().wrappers.forEach((issueLink) => {
        expect(issueLink.props('isJira')).toBe(isJira);
      });
    });
  });
});
