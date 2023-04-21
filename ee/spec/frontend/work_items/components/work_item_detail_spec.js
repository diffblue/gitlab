import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemWeight from 'ee/work_items/components/work_item_weight.vue';
import WorkItemProgress from 'ee/work_items/components/work_item_progress.vue';
import WorkItemIteration from 'ee/work_items/components/work_item_iteration.vue';
import WorkItemHealthStatus from 'ee/work_items/components/work_item_health_status.vue';
import workItemWeightSubscription from 'ee/graphql_shared/subscriptions/issuable_weight.subscription.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  workItemDatesSubscriptionResponse,
  workItemTitleSubscriptionResponse,
  workItemByIidResponseFactory as workItemResponseFactory,
  workItemWeightSubscriptionResponse,
  workItemAssigneesSubscriptionResponse,
  workItemIterationSubscriptionResponse,
  workItemMilestoneSubscriptionResponse,
  workItemHealthStatusSubscriptionResponse,
} from 'jest/work_items/mock_data';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemDatesSubscription from '~/graphql_shared/subscriptions/work_item_dates.subscription.graphql';
import workItemTitleSubscription from '~/work_items/graphql/work_item_title.subscription.graphql';
import workItemAssigneesSubscription from '~/work_items/graphql/work_item_assignees.subscription.graphql';
import workItemMilestoneSubscription from '~/work_items/graphql/work_item_milestone.subscription.graphql';
import workItemIterationSubscription from 'ee/work_items/graphql/work_item_iteration.subscription.graphql';
import workItemHealthStatusSubscription from 'ee/work_items/graphql/work_item_health_status.subscription.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';

describe('WorkItemDetail component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true, canDelete: true });
  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const datesSubscriptionHandler = jest.fn().mockResolvedValue(workItemDatesSubscriptionResponse);
  const titleSubscriptionHandler = jest.fn().mockResolvedValue(workItemTitleSubscriptionResponse);
  const weightSubscriptionHandler = jest.fn().mockResolvedValue(workItemWeightSubscriptionResponse);
  const assigneesSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemAssigneesSubscriptionResponse);
  const milestoneSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemMilestoneSubscriptionResponse);
  const iterationSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemIterationSubscriptionResponse);
  const healthStatusSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemHealthStatusSubscriptionResponse);

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findWorkItemWeight = () => wrapper.findComponent(WorkItemWeight);
  const findWorkItemProgress = () => wrapper.findComponent(WorkItemProgress);
  const findWorkItemIteration = () => wrapper.findComponent(WorkItemIteration);
  const findWorkItemHealthStatus = () => wrapper.findComponent(WorkItemHealthStatus);

  const createComponent = ({
    handler = successHandler,
    workItemsMvcEnabled = false,
    confidentialityMock = [updateWorkItemMutation, jest.fn()],
  } = {}) => {
    wrapper = shallowMount(WorkItemDetail, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, handler],
        [workItemDatesSubscription, datesSubscriptionHandler],
        [workItemTitleSubscription, titleSubscriptionHandler],
        [workItemWeightSubscription, weightSubscriptionHandler],
        [workItemAssigneesSubscription, assigneesSubscriptionHandler],
        [workItemIterationSubscription, iterationSubscriptionHandler],
        [workItemMilestoneSubscription, milestoneSubscriptionHandler],
        [workItemHealthStatusSubscription, healthStatusSubscriptionHandler],
        confidentialityMock,
      ]),
      provide: {
        glFeatures: {
          workItemsMvc: workItemsMvcEnabled,
        },
        hasIssueWeightsFeature: true,
        hasIterationsFeature: true,
        hasIssuableHealthStatusFeature: true,
        hasOkrsFeature: true,
        projectNamespace: 'namespace',
        fullPath: 'group/project',
      },
      propsData: {
        workItemId: workItemQueryResponse.data.workspace.workItems.nodes[0].id,
        workItemIid: '1',
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
        const handler = jest.fn().mockResolvedValue(response);
        createComponent({ handler });
        await waitForPromises();

        expect(findWorkItemIteration().exists()).toBe(exists);
      });
    });

    it('shows an error message when it emits an `error` event', async () => {
      createComponent();
      await waitForPromises();
      const updateError = 'Failed to update';

      findWorkItemIteration().vm.$emit('error', updateError);
      await waitForPromises();

      expect(findAlert().text()).toBe(updateError);
    });
  });

  describe('weight widget', () => {
    describe.each`
      description                               | weightWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}             | ${true}
      ${'when widget is not returned from API'} | ${false}            | ${false}
    `('$description', ({ weightWidgetPresent, exists }) => {
      it(`${weightWidgetPresent ? 'renders' : 'does not render'} weight component`, async () => {
        const response = workItemResponseFactory({ weightWidgetPresent });
        const handler = jest.fn().mockResolvedValue(response);
        createComponent({ handler });
        await waitForPromises();

        expect(findWorkItemWeight().exists()).toBe(exists);
      });
    });

    it('shows an error message when it emits an `error` event', async () => {
      createComponent();
      await waitForPromises();
      const updateError = 'Failed to update';

      findWorkItemWeight().vm.$emit('error', updateError);
      await waitForPromises();

      expect(findAlert().text()).toBe(updateError);
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
      } healthStatus component`, async () => {
        const response = workItemResponseFactory({ healthStatusWidgetPresent });
        const handler = jest.fn().mockResolvedValue(response);
        createComponent({ handler });
        await waitForPromises();

        expect(findWorkItemHealthStatus().exists()).toBe(exists);
      });
    });

    it('shows an error message when it emits an `error` event', async () => {
      createComponent();
      await waitForPromises();
      const updateError = 'Failed to update';

      findWorkItemHealthStatus().vm.$emit('error', updateError);
      await waitForPromises();

      expect(findAlert().text()).toBe(updateError);
    });
  });

  describe('progress widget', () => {
    describe.each`
      description                               | progressWidgetPresent | exists
      ${'when widget is returned from API'}     | ${true}               | ${true}
      ${'when widget is not returned from API'} | ${false}              | ${false}
    `('$description', ({ progressWidgetPresent, exists }) => {
      it(`${
        progressWidgetPresent ? 'renders' : 'does not render'
      } progress component`, async () => {
        const response = workItemResponseFactory({ progressWidgetPresent });
        const handler = jest.fn().mockResolvedValue(response);
        createComponent({ handler });
        await waitForPromises();

        expect(findWorkItemProgress().exists()).toBe(exists);
      });
    });

    it('shows an error message when it emits an `error` event', async () => {
      createComponent();
      await waitForPromises();
      const updateError = 'Failed to update';

      findWorkItemProgress().vm.$emit('error', updateError);
      await waitForPromises();

      expect(findAlert().text()).toBe(updateError);
    });
  });
});
