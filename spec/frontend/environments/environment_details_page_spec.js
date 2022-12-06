import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from '../__helpers__/mock_apollo_helper';
import waitForPromises from '../__helpers__/wait_for_promises';
import EnvironmentsDetailPage from '../../../app/assets/javascripts/environments/environment_details/index.vue';
import getEnvironmentDetails from '../../../app/assets/javascripts/environments/graphql/queries/environment_details.query.graphql';
import { resolvedEnvironmentDetails } from './graphql/mock_data';

describe('~/environments/environment_details/page.vue', () => {
  Vue.use(VueApollo);

  let wrapper;

  const createWrapper = () => {
    const mockApollo = createMockApollo([
      [getEnvironmentDetails, jest.fn().mockResolvedValue(resolvedEnvironmentDetails)],
    ]);

    return mountExtended(EnvironmentsDetailPage, {
      apolloProvider: mockApollo,
      propsData: {
        projectFullPath: 'gitlab-group/test-project',
        environmentName: 'test-environment-name',
      },
    });
  };

  describe('when fetching data', () => {
    it('should show a loading indicator', () => {
      wrapper = createWrapper();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.findComponent(GlTableLite).exists()).not.toBe(true);
    });
  });

  describe('when data is fetched', () => {
    beforeEach(async () => {
      wrapper = createWrapper();
      await waitForPromises();
    });

    it('should render a table when query is loaded', async () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).not.toBe(true);
      expect(wrapper.findComponent(GlTableLite).exists()).toBe(true);
    });
  });
});
