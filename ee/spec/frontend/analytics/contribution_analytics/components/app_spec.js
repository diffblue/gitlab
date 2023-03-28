import VueApollo from 'vue-apollo';
import Vue from 'vue';
import * as Sentry from '@sentry/browser';
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import App from 'ee/analytics/contribution_analytics/components/app.vue';
import contributionsQuery from 'ee/analytics/contribution_analytics/graphql/contributions.query.graphql';
import { MOCK_CONTRIBUTIONS_RESPONSE } from '../mock_data';

jest.mock('@sentry/browser');

Vue.use(VueApollo);

describe('Contribution Analytics App', () => {
  let wrapper;

  const mockContributionsHandler = jest.fn();
  const createMockApolloProvider = (contributionsQueryResolver) =>
    createMockApollo([
      [contributionsQuery, mockContributionsHandler.mockResolvedValue(contributionsQueryResolver)],
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

    expect(Sentry.captureException).toHaveBeenCalled();
    expect(findErrorAlert().exists()).toBe(true);
    expect(findErrorAlert().text()).toEqual(wrapper.vm.$options.i18n.error);
  });

  it('fetches paginated data', async () => {
    const mockApollo = createMockApolloProvider(MOCK_CONTRIBUTIONS_RESPONSE);
    createWrapper({ mockApollo });
    await waitForPromises();

    expect(mockContributionsHandler).toHaveBeenCalledWith({
      ...wrapper.props(),
      nextPageCursor: '',
    });
  });
});
