import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import App from 'ee/analytics/contribution_analytics/components/app.vue';
import contributionsQuery from 'ee/analytics/contribution_analytics/graphql/contributions.query.graphql';

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
});
