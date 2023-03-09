import { GlAlert, GlLink } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { mount, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import createJiraIssue from 'ee/vue_shared/security_reports/components/create_jira_issue.vue';
import RelatedJiraIssues, { i18n } from 'ee/vulnerabilities/components/related_jira_issues.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { sprintf } from '~/locale';

const mockAxios = new MockAdapter(axios);

describe('EE RelatedJiraIssues Component', () => {
  let wrapper;

  const defaultProvide = {
    createJiraIssueUrl: 'http://createNewJiraIssue',
    relatedJiraIssuesPath: 'http://fetchRelatedIssues',
    relatedJiraIssuesHelpPath: 'http://helpPage',
    jiraIntegrationSettingsPath: 'http://jiraIntegrationSettings',
  };

  const TEST_ISSUES = [
    {
      web_url: 'http://example.com',
      title: 'Issue #1',
      references: { relative: 'TES-1' },
    },
    {
      web_url: 'http://example.com',
      title: 'Issue #2',
      references: { relative: 'TES-2' },
    },
  ];

  const createWrapper = (mountFn, { createVulnerabilityJiraIssueViaGraphql = true } = {}) => () => {
    return extendedWrapper(
      mountFn(RelatedJiraIssues, {
        provide: {
          ...defaultProvide,
          ...{ vulnerabilityId: 1 },
          glFeatures: {
            createVulnerabilityJiraIssueViaGraphql,
          },
        },
      }),
    );
  };
  const createFullWrapper = createWrapper(mount);
  const createShallowWrapper = createWrapper(shallowMount);

  const withResponse = async (
    createWrapperFn,
    { statusCode = HTTP_STATUS_OK, data, waitForRequestsToFinish = true } = {},
  ) => {
    mockAxios.onGet(defaultProvide.relatedJiraIssuesPath).replyOnce(statusCode, data);
    const wrapperWithResponse = createWrapperFn();

    if (waitForRequestsToFinish) {
      await axios.waitForAll();
    }

    return wrapperWithResponse;
  };

  const withinComponent = () => within(wrapper.element);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findRelatedJiraIssuesCount = () => wrapper.findByTestId('related-jira-issues-count');
  const findCreateJiraIssueLink = () => wrapper.findByTestId('create-new-jira-issue-link');
  const findRelatedJiraIssuesSection = () => wrapper.findByTestId('related-jira-issues-section');
  const withinRelatedJiraIssuesSection = () => within(findRelatedJiraIssuesSection().element);
  const findShowCreateJiraIssueErrorAlert = () =>
    wrapper.findByTestId('create-jira-issue-error-alert');
  const findCreateJiraIssueComponent = () => wrapper.findComponent(createJiraIssue);
  afterEach(() => {
    mockAxios.reset();
  });

  describe('fetch related issues error message', () => {
    it('is not showing by default', () => {
      wrapper = createShallowWrapper();

      expect(findAlert().exists()).toBe(false);
    });

    describe('with error while fetching related Jira issues', () => {
      beforeEach(async () => {
        wrapper = await withResponse(createFullWrapper, { statusCode: HTTP_STATUS_BAD_REQUEST });
      });

      it('shows when there is an error while fetching the related jira issues', () => {
        expect(findAlert().exists()).toBe(true);
      });

      it('shows a message describing the error', () => {
        const expectedLinkText = sprintf(i18n.fetchErrorMessage, { linkStart: '', linkEnd: '' });
        expect(findAlert().text()).toBe(expectedLinkText);
      });

      it('shows a link to the Jira integration settings', () => {
        expect(findAlert().findComponent(GlLink).attributes('href')).toBe(
          defaultProvide.jiraIntegrationSettingsPath,
        );
      });

      it('can be dismissed', async () => {
        findAlert().vm.$emit('dismiss');
        await nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });
  });

  describe('header', () => {
    describe('static content', () => {
      beforeEach(() => {
        wrapper = createFullWrapper();
      });

      it('shows a heading', () => {
        expect(withinComponent().getByRole('heading', { name: i18n.cardHeading })).not.toBe(
          undefined,
        );
      });

      it('shows a link to a help page', () => {
        expect(
          withinComponent().getByLabelText(i18n.helpPageLinkLabel, {
            selector: `[href="${defaultProvide.relatedJiraIssuesHelpPath}"]`,
          }),
        ).not.toBe(undefined);
      });

      describe('when createVulnerabilityJiraIssueViaGraphql Flag is on', () => {
        it('shows createJiraIssue Component', () => {
          expect(findCreateJiraIssueComponent().exists()).toBe(true);
        });

        it('does not show CreateJiraIssueButton', () => {
          expect(findCreateJiraIssueLink().exists()).toBe(false);
        });
      });

      describe('when createVulnerabilityJiraIssueViaGraphql Flag is off', () => {
        beforeEach(async () => {
          wrapper = await withResponse(
            createWrapper(mount, { createVulnerabilityJiraIssueViaGraphql: false }),
          );
        });

        it('does not show createJiraIssue Component', () => {
          expect(findCreateJiraIssueComponent().exists()).toBe(false);
        });

        it('shows CreateJiraIssueButton', () => {
          expect(findCreateJiraIssueLink().props()).toMatchObject({
            variant: 'confirm',
            category: 'secondary',
            icon: 'external-link',
          });

          expect(findCreateJiraIssueLink().attributes()).toMatchObject({
            href: defaultProvide.createJiraIssueUrl,
          });
        });
      });

      it('should not show showCreateJiraIssueErrorAlert Banner', () => {
        expect(findShowCreateJiraIssueErrorAlert().exists()).toBe(false);
      });

      it('shows showCreateJiraIssueErrorAlert Banner when createJiraIssue emits an error', async () => {
        findCreateJiraIssueComponent().vm.$emit('create-jira-issue-error', 'test-error-message');
        await nextTick();
        const alert = findShowCreateJiraIssueErrorAlert();
        expect(alert.exists()).toBe(true);
        expect(alert.text()).toMatch('test-error-message');
      });
    });

    describe('related issues count', () => {
      it('shows a placeholder while fetching', async () => {
        wrapper = await withResponse(createFullWrapper, {
          data: [],
          waitForRequestsToFinish: false,
        });

        expect(findRelatedJiraIssuesCount().text()).toBe('...');
      });

      it('shows the number of fetched issues', async () => {
        wrapper = await withResponse(createFullWrapper, {
          data: TEST_ISSUES,
        });

        expect(findRelatedJiraIssuesCount().text()).toBe(`${TEST_ISSUES.length}`);
      });
    });
  });

  describe('body', () => {
    describe.each(TEST_ISSUES)('related Jira issues', (issue) => {
      beforeEach(async () => {
        wrapper = await withResponse(createFullWrapper, {
          data: TEST_ISSUES,
        });
      });

      it('shows the issue title with a link to the issue', () => {
        expect(
          withinRelatedJiraIssuesSection().getByText(issue.title, {
            selector: `[href="${issue.web_url}"]`,
          }),
        ).not.toBe(undefined);
      });

      it('shows the related Jira project-id', () => {
        expect(
          withinRelatedJiraIssuesSection().getByText(`#${issue.references.relative}`),
        ).not.toBe(undefined);
      });
    });

    it('is hidden when there are no related issues', async () => {
      wrapper = await withResponse(createFullWrapper, {
        data: [],
      });

      expect(findRelatedJiraIssuesSection().isVisible()).toBe(false);
    });
  });
});
