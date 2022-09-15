import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemWeight from 'ee/work_items/components/work_item_weight.vue';
import workItemWeightSubscription from 'ee/work_items/graphql/work_item_weight.subscription.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  workItemDatesSubscriptionResponse,
  workItemTitleSubscriptionResponse,
  workItemResponseFactory,
  workItemWeightSubscriptionResponse,
} from 'jest/work_items/mock_data';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemDatesSubscription from '~/work_items/graphql/work_item_dates.subscription.graphql';
import workItemTitleSubscription from '~/work_items/graphql/work_item_title.subscription.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';

describe('WorkItemDetail component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true, canDelete: true });
  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const datesSubscriptionHandler = jest.fn().mockResolvedValue(workItemDatesSubscriptionResponse);
  const titleSubscriptionHandler = jest.fn().mockResolvedValue(workItemTitleSubscriptionResponse);
  const weightSubscriptionHandler = jest.fn().mockResolvedValue(workItemWeightSubscriptionResponse);

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findWorkItemWeight = () => wrapper.findComponent(WorkItemWeight);

  const createComponent = ({
    handler = successHandler,
    confidentialityMock = [updateWorkItemMutation, jest.fn()],
  } = {}) => {
    wrapper = shallowMount(WorkItemDetail, {
      apolloProvider: createMockApollo([
        [workItemQuery, handler],
        [workItemDatesSubscription, datesSubscriptionHandler],
        [workItemTitleSubscription, titleSubscriptionHandler],
        [workItemWeightSubscription, weightSubscriptionHandler],
        confidentialityMock,
      ]),
      provide: {
        hasIssueWeightsFeature: true,
      },
      propsData: {
        workItemId: workItemQueryResponse.data.workItem.id,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
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
