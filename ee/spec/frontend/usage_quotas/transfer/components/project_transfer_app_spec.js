import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ProjectTransferApp from 'ee/usage_quotas/transfer/components/project_transfer_app.vue';
import UsageByType from 'ee/usage_quotas/transfer/components/usage_by_type.vue';
import getProjectDataTransferEgress from 'ee/usage_quotas/transfer/graphql/queries/get_project_data_transfer_egress.query.graphql';
import { getProjectDataTransferEgressResponse } from '../mock_data';

describe('ProjectTransferApp', () => {
  let wrapper;

  const {
    nodes: egressNodes,
  } = getProjectDataTransferEgressResponse.data.project.dataTransfer.egressNodes;

  const defaultProvide = {
    fullPath: 'h5bp/html5-boilerplate',
  };

  const createComponent = ({
    provide = {},
    requestHandlers = [
      [
        getProjectDataTransferEgress,
        jest.fn().mockResolvedValueOnce(getProjectDataTransferEgressResponse),
      ],
    ],
  } = {}) => {
    Vue.use(VueApollo);

    wrapper = shallowMountExtended(ProjectTransferApp, {
      provide: { ...defaultProvide, ...provide },
      apolloProvider: createMockApollo(requestHandlers),
    });
  };

  const findUsageByType = () => wrapper.findComponent(UsageByType);
  const findGlALert = () => wrapper.findComponent(GlAlert);

  describe('when GraphQL request is loading', () => {
    beforeEach(() => {
      createComponent({
        requestHandlers: [
          [getProjectDataTransferEgress, jest.fn().mockReturnValueOnce(new Promise(() => {}))],
        ],
      });
    });

    it('sets `UsageByType` `loading` prop to `true`', () => {
      expect(findUsageByType().props('loading')).toBe(true);
    });
  });

  describe('when GraphQL request is successful', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('renders `UsageByType` component and correctly passes props', () => {
      expect(findUsageByType().props()).toMatchObject({
        egressNodes,
        loading: false,
      });
    });
  });

  describe('when GraphQL request is not successful', () => {
    beforeEach(async () => {
      createComponent({
        requestHandlers: [[getProjectDataTransferEgress, jest.fn().mockRejectedValueOnce()]],
      });

      await waitForPromises();
    });

    it('shows error alert', () => {
      expect(findGlALert().text()).toBe(ProjectTransferApp.i18n.ERROR_MESSAGE);
    });

    it('allows error alert to be closed', async () => {
      findGlALert().vm.$emit('dismiss');
      await nextTick();

      expect(findGlALert().exists()).toBe(false);
    });
  });
});
