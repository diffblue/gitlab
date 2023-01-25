import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PushesChart from 'ee/analytics/contribution_analytics/components/pushes_chart.vue';
import MergeRequestsChart from 'ee/analytics/contribution_analytics/components/merge_requests_chart.vue';
import IssuesChart from 'ee/analytics/contribution_analytics/components/issues_chart.vue';
import GroupMembersTable from 'ee/analytics/contribution_analytics/components/group_members_table.vue';
import App from 'ee/analytics/contribution_analytics/components/app.vue';
import contributionsQuery from 'ee/analytics/contribution_analytics/graphql/contributions.query.graphql';
import { MOCK_CONTRIBUTIONS } from '../mock_data';

Vue.use(VueApollo);

describe('Contribution Analytics App', () => {
  let wrapper;

  const createMockApolloProvider = (contributionsQueryResolver) =>
    createMockApollo([
      [contributionsQuery, jest.fn().mockResolvedValue(contributionsQueryResolver)],
    ]);

  const createWrapper = ({ mockApollo }) => {
    wrapper = shallowMount(App, {
      apolloProvider: mockApollo,
      propsData: {
        fullPath: 'test',
        startDate: '2000-01-01',
        endDate: '2000-12-31',
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findErrorAlert = () => wrapper.findComponent(GlAlert);
  const findPushesChart = () => wrapper.findComponent(PushesChart);
  const findMergeRequestsChart = () => wrapper.findComponent(MergeRequestsChart);
  const findIssuesChart = () => wrapper.findComponent(IssuesChart);
  const findGroupMembersTable = () => wrapper.findComponent(GroupMembersTable);

  it('renders the loading spinner when the request is pending', async () => {
    const mockApollo = createMockApolloProvider({ data: null });
    createWrapper({ mockApollo });

    expect(findLoadingIcon().exists()).toBe(true);
    await waitForPromises();
    expect(findLoadingIcon().exists()).toBe(false);
  });

  it('renders the error alert if the request fails', async () => {
    const mockApollo = createMockApolloProvider({ data: null });
    createWrapper({ mockApollo });
    await waitForPromises();

    expect(findErrorAlert().exists()).toBe(true);
    expect(findErrorAlert().text()).toEqual(wrapper.vm.$options.i18n.error);
  });

  describe('request complete', () => {
    beforeEach(async () => {
      const mockApollo = createMockApolloProvider({
        data: { group: { id: 'id', contributions: { nodes: MOCK_CONTRIBUTIONS } } },
      });
      createWrapper({ mockApollo });
      await waitForPromises();
    });

    it('formats the pushes data for the PushesChart', () => {
      expect(findPushesChart().props('pushes')).toEqual([
        { user: 'Patrick', count: 12 },
        { user: 'Mr Krabs', count: 47 },
      ]);
    });

    it('formats the merge requests data for the MergeRequestsChart', () => {
      expect(findMergeRequestsChart().props('mergeRequests')).toEqual([
        { user: 'Spongebob', closed: 75, created: 234, merged: 35 },
        { user: 'Mr Krabs', closed: 99, created: 0, merged: 15 },
      ]);
    });

    it('formats the issues data for the IssuesChart', () => {
      expect(findIssuesChart().props('issues')).toEqual([
        { user: 'Spongebob', closed: 34, created: 75 },
        { user: 'Patrick', closed: 57, created: 55 },
      ]);
    });

    it('passes the raw contributions data to the GroupMembersTable', () => {
      expect(findGroupMembersTable().props('contributions')).toEqual(MOCK_CONTRIBUTIONS);
    });
  });
});
