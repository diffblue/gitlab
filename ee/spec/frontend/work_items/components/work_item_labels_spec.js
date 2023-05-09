import { GlLabel } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import labelSearchQuery from '~/sidebar/components/labels/labels_select_widget/graphql/project_labels.query.graphql';
import workItemLabelsSubscription from 'ee_else_ce/work_items/graphql/work_item_labels.subscription.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import {
  projectLabelsResponse,
  workItemByIidResponseFactory,
  updateWorkItemMutationResponse,
  workItemLabelsSubscriptionResponse,
} from 'jest/work_items/mock_data';

Vue.use(VueApollo);

const workItemId = 'gid://gitlab/WorkItem/1';

describe('WorkItemLabels component', () => {
  let wrapper;

  const findScopedLabel = () =>
    wrapper.findAllComponents(GlLabel).filter((label) => label.props('scoped'));

  const workItemQuerySuccess = jest.fn().mockResolvedValue(workItemByIidResponseFactory());
  const successSearchQueryHandler = jest.fn().mockResolvedValue(projectLabelsResponse);
  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponse);
  const subscriptionHandler = jest.fn().mockResolvedValue(workItemLabelsSubscriptionResponse);

  const createComponent = ({
    canUpdate = true,
    workItemQueryHandler = workItemQuerySuccess,
    searchQueryHandler = successSearchQueryHandler,
    updateWorkItemMutationHandler = successUpdateWorkItemMutationHandler,
  } = {}) => {
    wrapper = mount(WorkItemLabels, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, workItemQueryHandler],
        [labelSearchQuery, searchQueryHandler],
        [updateWorkItemMutation, updateWorkItemMutationHandler],
        [workItemLabelsSubscription, subscriptionHandler],
      ]),
      provide: {
        fullPath: 'test-project-path',
      },
      propsData: {
        workItemId,
        workItemIid: '1',
        canUpdate,
      },
    });
  };

  describe('allows scoped labels', () => {
    it.each([true, false])('= %s', async (allowsScopedLabels) => {
      const workItemQueryHandler = jest
        .fn()
        .mockResolvedValue(workItemByIidResponseFactory({ allowsScopedLabels }));

      createComponent({ workItemQueryHandler });

      await waitForPromises();

      expect(findScopedLabel().exists()).toBe(allowsScopedLabels);
    });
  });
});
