import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';

import * as JiraIssuesShowApi from 'ee/integrations/jira/issues_show/api';
import JiraIssuesShow from 'ee/integrations/jira/issues_show/components/jira_issues_show_root.vue';
import JiraIssueSidebar from 'ee/integrations/jira/issues_show/components/sidebar/jira_issues_sidebar_root.vue';
import { issueStates } from 'ee/external_issues_show/constants';
import waitForPromises from 'helpers/wait_for_promises';
import IssuableHeader from '~/issuable_show/components/issuable_header.vue';
import IssuableShow from '~/issuable_show/components/issuable_show_root.vue';
import IssuableSidebar from '~/issuable_sidebar/components/issuable_sidebar_root.vue';
import axios from '~/lib/utils/axios_utils';
import { mockJiraIssue } from '../mock_data';

const mockJiraIssuesShowPath = 'jira_issues_show_path';

describe('JiraIssuesShow', () => {
  let wrapper;
  let mockAxios;

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findIssuableShow = () => wrapper.findComponent(IssuableShow);
  const findJiraIssueSidebar = () => wrapper.findComponent(JiraIssueSidebar);
  const findIssuableShowStatusBadge = () =>
    wrapper.findComponent(IssuableHeader).find('[data-testid="status"]');

  const createComponent = () => {
    wrapper = shallowMount(JiraIssuesShow, {
      stubs: {
        IssuableHeader,
        IssuableShow,
        IssuableSidebar,
      },
      provide: {
        issuesShowPath: mockJiraIssuesShowPath,
      },
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
    wrapper.destroy();
  });

  describe('when issue is loading', () => {
    it('renders GlLoadingIcon', () => {
      createComponent();

      expect(findGlLoadingIcon().exists()).toBe(true);
      expect(findGlAlert().exists()).toBe(false);
      expect(findIssuableShow().exists()).toBe(false);
    });
  });

  describe('when error occurs during fetch', () => {
    it('renders error message', async () => {
      mockAxios.onGet(mockJiraIssuesShowPath).replyOnce(500);
      createComponent();

      await waitForPromises();

      const alert = findGlAlert();

      expect(findGlLoadingIcon().exists()).toBe(false);
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(
        'Failed to load Jira issue. View the issue in Jira, or reload the page.',
      );
      expect(alert.props('variant')).toBe('danger');
      expect(findIssuableShow().exists()).toBe(false);
    });
  });

  it('renders IssuableShow', async () => {
    mockAxios.onGet(mockJiraIssuesShowPath).replyOnce(200, mockJiraIssue);
    createComponent();

    await waitForPromises();

    expect(findGlLoadingIcon().exists()).toBe(false);
    expect(findIssuableShow().exists()).toBe(true);
  });

  describe.each`
    state                 | statusIcon              | statusBadgeClass             | badgeText
    ${issueStates.OPENED} | ${'issue-open-m'}       | ${'status-box-open'}         | ${'Open'}
    ${issueStates.CLOSED} | ${'mobile-issue-close'} | ${'status-box-issue-closed'} | ${'Closed'}
  `('when issue state is `$state`', ({ state, statusIcon, statusBadgeClass, badgeText }) => {
    beforeEach(async () => {
      mockAxios.onGet(mockJiraIssuesShowPath).replyOnce(200, { ...mockJiraIssue, state });
      createComponent();

      await waitForPromises();
    });

    it('sets `statusIcon` prop correctly', () => {
      expect(findIssuableShow().props('statusIcon')).toBe(statusIcon);
    });

    it('sets `statusBadgeClass` prop correctly', () => {
      expect(findIssuableShow().props('statusBadgeClass')).toBe(statusBadgeClass);
    });

    it('renders correct status badge text', () => {
      expect(findIssuableShowStatusBadge().text()).toBe(badgeText);
    });
  });

  describe('JiraIssueSidebar events', () => {
    beforeEach(async () => {
      mockAxios.onGet(mockJiraIssuesShowPath).replyOnce(200, mockJiraIssue);
      createComponent();

      await waitForPromises();
    });

    it('updates issue labels on issue-labels-updated', async () => {
      const updateIssueSpy = jest.spyOn(JiraIssuesShowApi, 'updateIssue').mockResolvedValue();

      const labels = [{ id: 'ecosystem' }];

      findJiraIssueSidebar().vm.$emit('issue-labels-updated', labels);
      await wrapper.vm.$nextTick();

      expect(updateIssueSpy).toHaveBeenCalledWith(expect.any(Object), { labels });
      expect(findJiraIssueSidebar().props('isUpdatingLabels')).toBe(true);

      await waitForPromises();

      expect(findJiraIssueSidebar().props('isUpdatingLabels')).toBe(false);
    });

    it('fetches issue statuses on issue-status-fetch', async () => {
      const fetchIssueStatusesSpy = jest
        .spyOn(JiraIssuesShowApi, 'fetchIssueStatuses')
        .mockResolvedValue();

      findJiraIssueSidebar().vm.$emit('issue-status-fetch');
      await wrapper.vm.$nextTick();

      expect(fetchIssueStatusesSpy).toHaveBeenCalled();
      expect(findJiraIssueSidebar().props('isLoadingStatus')).toBe(true);

      await waitForPromises();

      expect(findJiraIssueSidebar().props('isLoadingStatus')).toBe(false);
    });

    it('updates issue status on issue-status-updated', async () => {
      const updateIssueSpy = jest.spyOn(JiraIssuesShowApi, 'updateIssue').mockResolvedValue();

      const status = 'In Review';

      findJiraIssueSidebar().vm.$emit('issue-status-updated', status);
      await wrapper.vm.$nextTick();

      expect(updateIssueSpy).toHaveBeenCalledWith(expect.any(Object), { status });
      expect(findJiraIssueSidebar().props('isUpdatingStatus')).toBe(true);

      await waitForPromises();

      expect(findJiraIssueSidebar().props('isUpdatingStatus')).toBe(false);
    });

    it('updates `sidebarExpanded` prop on `sidebar-toggle` event', async () => {
      const jiraIssueSidebar = findJiraIssueSidebar();
      expect(jiraIssueSidebar.props('sidebarExpanded')).toBe(true);

      jiraIssueSidebar.vm.$emit('sidebar-toggle');
      await wrapper.vm.$nextTick();

      expect(jiraIssueSidebar.props('sidebarExpanded')).toBe(false);
    });
  });
});
