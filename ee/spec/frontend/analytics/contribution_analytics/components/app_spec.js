import VueApollo from 'vue-apollo';
import Vue from 'vue';
import * as Sentry from '@sentry/browser';
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import App from 'ee/analytics/contribution_analytics/components/app.vue';
import GroupMembersTable from 'ee/analytics/contribution_analytics/components/group_members_table.vue';
import contributionsQuery from 'ee/analytics/contribution_analytics/graphql/contributions.query.graphql';

jest.mock('@sentry/browser');

Vue.use(VueApollo);

describe('Contribution Analytics App', () => {
  let wrapper;

  const wrapApiResponse = (nodes, endCursor = '') => ({
    data: {
      group: {
        id: 'YEET',
        contributions: {
          nodes,
          pageInfo: {
            endCursor,
            hasNextPage: endCursor !== '',
          },
        },
      },
    },
  });

  const createMockContribution = (userId, metricValue) => ({
    repoPushed: metricValue,
    mergeRequestsCreated: metricValue,
    mergeRequestsMerged: metricValue,
    mergeRequestsClosed: metricValue,
    mergeRequestsApproved: metricValue,
    issuesCreated: metricValue,
    issuesClosed: metricValue,
    totalEvents: metricValue,
    user: {
      id: userId,
      name: userId,
      webUrl: userId,
    },
  });

  const createWrapper = ({ contributionsQueryResolver }) => {
    const apolloProvider = createMockApollo(
      [[contributionsQuery, contributionsQueryResolver]],
      {},
      { typePolicies: { Query: { fields: { group: { merge: false } } } } },
    );

    wrapper = shallowMount(App, {
      apolloProvider,
      propsData: {
        fullPath: 'test',
        startDate: '2000-12-10',
        endDate: '2000-12-31',
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findErrorAlert = () => wrapper.findComponent(GlAlert);
  const findGroupMembersTable = () => wrapper.findComponent(GroupMembersTable);

  it('renders the loading spinner when the request is pending', async () => {
    const contributionsQueryResolver = jest.fn().mockResolvedValue({ data: null });
    createWrapper({ contributionsQueryResolver });

    expect(findLoadingIcon().exists()).toBe(true);
    await waitForPromises();
    expect(findLoadingIcon().exists()).toBe(false);
  });

  it('renders the error alert if the request fails', async () => {
    const contributionsQueryResolver = jest.fn().mockResolvedValue({ data: null });
    createWrapper({ contributionsQueryResolver });
    await waitForPromises();

    expect(Sentry.captureException).toHaveBeenCalled();
    expect(findErrorAlert().exists()).toBe(true);
    expect(findErrorAlert().text()).toEqual(wrapper.vm.$options.i18n.error);
  });

  it('fetches the data per week, using paginated requests when necessary', async () => {
    const userA = 'primary';
    const userB = 'secondary';
    const nextPageCursor = 'next';

    const contributionsQueryResolver = jest
      .fn()
      .mockResolvedValueOnce(wrapApiResponse([createMockContribution(userA, 100)], nextPageCursor))
      .mockResolvedValueOnce(wrapApiResponse([createMockContribution(userB, 5)]))
      .mockResolvedValueOnce(wrapApiResponse([createMockContribution(userA, 25)]))
      .mockResolvedValueOnce(wrapApiResponse([createMockContribution(userA, 50)], nextPageCursor))
      .mockResolvedValueOnce(wrapApiResponse([createMockContribution(userB, 7)]));

    createWrapper({ contributionsQueryResolver });
    await waitForPromises();

    expect(findGroupMembersTable().props('contributions')).toMatchSnapshot();
    expect(contributionsQueryResolver).toHaveBeenCalledTimes(5);
    [
      {
        endDate: '2000-12-17',
        nextPageCursor: '',
      },
      {
        endDate: '2000-12-17',
        nextPageCursor,
      },
      {
        startDate: '2000-12-18',
        endDate: '2000-12-25',
        nextPageCursor: '',
      },
      {
        startDate: '2000-12-26',
        endDate: '2000-12-31',
        nextPageCursor: '',
      },
      {
        startDate: '2000-12-26',
        endDate: '2000-12-31',
        nextPageCursor,
      },
    ].forEach((result) =>
      expect(contributionsQueryResolver).toHaveBeenCalledWith({
        ...wrapper.props(),
        ...result,
      }),
    );
  });
});
