import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemWeight from 'ee/work_items/components/work_item_weight.vue';
import WorkItemIteration from 'ee/work_items/components/work_item_iteration.vue';
import workItemWeightSubscription from 'ee/work_items/graphql/work_item_weight.subscription.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  workItemDatesSubscriptionResponse,
  workItemTitleSubscriptionResponse,
  workItemResponseFactory,
  workItemWeightSubscriptionResponse,
  workItemAssigneesSubscriptionResponse,
  workItemIterationSubscriptionResponse,
  workItemMilestoneSubscriptionResponse,
} from 'jest/work_items/mock_data';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemDatesSubscription from '~/work_items/graphql/work_item_dates.subscription.graphql';
import workItemTitleSubscription from '~/work_items/graphql/work_item_title.subscription.graphql';
import workItemAssigneesSubscription from '~/work_items/graphql/work_item_assignees.subscription.graphql';
import workItemMilestoneSubscription from '~/work_items/graphql/work_item_milestone.subscription.graphql';
import workItemIterationSubscription from 'ee/work_items/graphql/work_item_iteration.subscription.graphql';
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

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findWorkItemWeight = () => wrapper.findComponent(WorkItemWeight);
  const findWorkItemIteration = () => wrapper.findComponent(WorkItemIteration);

  const createComponent = ({
    handler = successHandler,
    workItemsMvc2Enabled = false,
    confidentialityMock = [updateWorkItemMutation, jest.fn()],
  } = {}) => {
    wrapper = shallowMount(WorkItemDetail, {
      apolloProvider: createMockApollo([
        [workItemQuery, handler],
        [workItemDatesSubscription, datesSubscriptionHandler],
        [workItemTitleSubscription, titleSubscriptionHandler],
        [workItemWeightSubscription, weightSubscriptionHandler],
        [workItemAssigneesSubscription, assigneesSubscriptionHandler],
        [workItemIterationSubscription, iterationSubscriptionHandler],
        [workItemMilestoneSubscription, milestoneSubscriptionHandler],
        confidentialityMock,
      ]),
      provide: {
        glFeatures: {
          workItemsMvc2: workItemsMvc2Enabled,
        },
        hasIssueWeightsFeature: true,
        hasIterationsFeature: true,
        projectNamespace: 'namespace',
        fullPath: 'group/project',
      },
      propsData: {
        workItemId: workItemQueryResponse.data.workItem.id,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

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
        createComponent({ handler, workItemsMvc2Enabled: true });
        await waitForPromises();

        expect(findWorkItemIteration().exists()).toBe(exists);
      });
    });

    it('shows an error message when it emits an `error` event', async () => {
      createComponent({ workItemsMvc2Enabled: true });
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
});
