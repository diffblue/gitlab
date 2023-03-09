import { mount } from '@vue/test-utils';
import { GlAlert, GlLink } from '@gitlab/ui';

import ExternalIssueAlert from 'ee/external_issues_show/components/external_issue_alert.vue';

describe('ExternalIssueAlert', () => {
  let wrapper;

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlLink = () => wrapper.findComponent(GlLink);

  const defaultProps = {
    issueTrackerName: 'Jira',
    issueUrl: 'https://example.atlassian.net/browse/FE-1',
  };

  const createComponent = ({ props } = {}) => {
    wrapper = mount(ExternalIssueAlert, {
      propsData: { ...defaultProps, ...props },
    });
  };

  describe('template', () => {
    describe.each`
      issueTrackerName
      ${'Jira'}
      ${'ZenTao'}
    `('when `issueTrackerName` is `$issueTrackerName`', ({ issueTrackerName }) => {
      it('renders GlAlert', () => {
        createComponent({
          props: { issueTrackerName },
        });

        expect(findGlAlert().props('title')).toBe(
          `This issue is synchronized with ${issueTrackerName}`,
        );
        expect(findGlAlert().text()).toContain(
          `Not all data may be displayed here. To view more details or make changes to this issue, go to ${issueTrackerName}`,
        );
      });
    });

    it('renders GlLink', () => {
      createComponent();

      expect(findGlLink().attributes('href')).toBe(defaultProps.issueUrl);
    });

    describe('when issueUrl is not provided', () => {
      it('does not render GlLink and falls back to plain text', () => {
        createComponent({
          props: { issueUrl: null },
        });

        expect(findGlLink().exists()).toBe(false);
        expect(findGlAlert().text()).toContain(
          'Not all data may be displayed here. To view more details or make changes to this issue, go to Jira',
        );
      });
    });
  });
});
