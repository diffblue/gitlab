import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import WorkItemProgress from 'ee/work_items/components/work_item_progress.vue';
import WorkItemHealthStatus from 'ee/work_items/components/work_item_health_status.vue';
import WorkItemWeight from 'ee/work_items/components/work_item_weight.vue';
import WorkItemIteration from 'ee/work_items/components/work_item_iteration.vue';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { workItemResponseFactory } from 'jest/work_items/mock_data';

import WorkItemAttributesWrapper from '~/work_items/components/work_item_attributes_wrapper.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemUpdatedSubscription from '~/work_items/graphql/work_item_updated.subscription.graphql';

describe('EE WorkItemAttributesWrapper component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true, canDelete: true });

  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const workItemUpdatedSubscriptionHandler = jest
    .fn()
    .mockResolvedValue({ data: { workItemUpdated: null } });

  const findWorkItemIteration = () => wrapper.findComponent(WorkItemIteration);
  const findWorkItemWeight = () => wrapper.findComponent(WorkItemWeight);
  const findWorkItemProgress = () => wrapper.findComponent(WorkItemProgress);
  const findWorkItemHealthStatus = () => wrapper.findComponent(WorkItemHealthStatus);

  const createComponent = ({
    workItem = workItemQueryResponse.data.workItem,
    handler = successHandler,
    confidentialityMock = [updateWorkItemMutation, jest.fn()],
  } = {}) => {
    wrapper = shallowMount(WorkItemAttributesWrapper, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, handler],
        [workItemUpdatedSubscription, workItemUpdatedSubscriptionHandler],
        confidentialityMock,
      ]),
      propsData: {
        workItem,
      },
      provide: {
        hasIssueWeightsFeature: true,
        hasIterationsFeature: true,
        hasOkrsFeature: true,
        hasIssuableHealthStatusFeature: true,
        projectNamespace: 'namespace',
        fullPath: 'group/project',
      },
    });
  };

  describe('iteration widget', () => {
    describe.each`
      description                               | iterationWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}                | ${true}
      ${'when widget is not returned from API'} | ${false}               | ${false}
    `('$description', ({ iterationWidgetPresent, exists }) => {
      it(`${
        iterationWidgetPresent ? 'renders' : 'does not render'
      } iteration component`, async () => {
        const response = workItemResponseFactory({ iterationWidgetPresent });
        createComponent({ workItem: response.data.workItem });
        await waitForPromises();

        expect(findWorkItemIteration().exists()).toBe(exists);
      });
    });

    it('emits an error event to the wrapper', async () => {
      createComponent();
      const updateError = 'Failed to update';

      findWorkItemIteration().vm.$emit('error', updateError);
      await nextTick();

      expect(wrapper.emitted('error')).toEqual([[updateError]]);
    });
  });

  describe('weight widget', () => {
    describe.each`
      description                               | weightWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}             | ${true}
      ${'when widget is not returned from API'} | ${false}            | ${false}
    `('$description', ({ weightWidgetPresent, exists }) => {
      it(`${weightWidgetPresent ? 'renders' : 'does not render'} weight component`, () => {
        const response = workItemResponseFactory({ weightWidgetPresent });
        createComponent({ workItem: response.data.workItem });

        expect(findWorkItemWeight().exists()).toBe(exists);
      });
    });

    it('emits an error event to the wrapper', async () => {
      const response = workItemResponseFactory({ weightWidgetPresent: true });
      createComponent({ workItem: response.data.workItem });
      const updateError = 'Failed to update';

      findWorkItemWeight().vm.$emit('error', updateError);
      await nextTick();

      expect(wrapper.emitted('error')).toEqual([[updateError]]);
    });
  });

  describe('health status widget', () => {
    describe.each`
      description                               | healthStatusWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}                   | ${true}
      ${'when widget is not returned from API'} | ${false}                  | ${false}
    `('$description', ({ healthStatusWidgetPresent, exists }) => {
      it(`${
        healthStatusWidgetPresent ? 'renders' : 'does not render'
      } healthStatus component`, () => {
        const response = workItemResponseFactory({ healthStatusWidgetPresent });
        createComponent({ workItem: response.data.workItem });

        expect(findWorkItemHealthStatus().exists()).toBe(exists);
      });
    });

    it('emits an error event to the wrapper', async () => {
      const response = workItemResponseFactory({ healthStatusWidgetPresent: true });
      createComponent({ workItem: response.data.workItem });
      const updateError = 'Failed to update';

      findWorkItemHealthStatus().vm.$emit('error', updateError);
      await nextTick();

      expect(wrapper.emitted('error')).toEqual([[updateError]]);
    });
  });

  describe('progress widget', () => {
    describe.each`
      description                               | progressWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}               | ${true}
      ${'when widget is not returned from API'} | ${false}              | ${false}
    `('$description', ({ progressWidgetPresent, exists }) => {
      it(`${progressWidgetPresent ? 'renders' : 'does not render'} progress component`, () => {
        const response = workItemResponseFactory({ progressWidgetPresent });
        createComponent({ workItem: response.data.workItem });

        expect(findWorkItemProgress().exists()).toBe(exists);
      });
    });

    it('emits an error event to the wrapper', async () => {
      const response = workItemResponseFactory({ progressWidgetPresent: true });
      createComponent({ workItem: response.data.workItem });
      const updateError = 'Failed to update';

      findWorkItemProgress().vm.$emit('error', updateError);
      await nextTick();

      expect(wrapper.emitted('error')).toEqual([[updateError]]);
    });
  });
});
