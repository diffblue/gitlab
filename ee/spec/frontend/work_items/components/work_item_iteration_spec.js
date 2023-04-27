import {
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlSkeletonLoader,
  GlDropdownText,
  GlFormGroup,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemIteration from 'ee/work_items/components/work_item_iteration.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIterationPeriod } from 'ee/iterations/utils';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import projectIterationsQuery from 'ee/work_items/graphql/project_iterations.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemIterationSubscription from 'ee/work_items/graphql/work_item_iteration.subscription.graphql';
import {
  groupIterationsResponse,
  groupIterationsResponseWithNoIterations,
  mockIterationWidgetResponse,
  updateWorkItemMutationResponse,
  workItemByIidResponseFactory,
  workItemIterationSubscriptionResponse,
  updateWorkItemMutationErrorResponse,
} from 'jest/work_items/mock_data';

describe('WorkItemIteration component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const workItemId = 'gid://gitlab/WorkItem/1';
  const workItemType = 'Task';

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findNoIterationDropdownItem = () => wrapper.findByTestId('no-iteration');
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownTexts = () => wrapper.findAllComponents(GlDropdownText);
  const findFirstDropdownItem = () => findDropdownItems().at(0);
  const findDropdownItemAtIndex = (index) => findDropdownItems().at(index);
  const findDisabledTextSpan = () => wrapper.findByTestId('disabled-text');
  const findDropdownTextAtIndex = (index) => findDropdownTexts().at(index);
  const findInputGroup = () => wrapper.findComponent(GlFormGroup);

  const workItemQueryResponse = workItemByIidResponseFactory({ canUpdate: true, canDelete: true });
  const workItemQueryHandler = jest.fn().mockResolvedValue(workItemQueryResponse);

  const networkResolvedValue = new Error();

  const iterationSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemIterationSubscriptionResponse);
  const successSearchQueryHandler = jest.fn().mockResolvedValue(groupIterationsResponse);
  const successSearchWithNoMatchingIterations = jest
    .fn()
    .mockResolvedValue(groupIterationsResponseWithNoIterations);

  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponse);

  const showDropdown = () => {
    findDropdown().vm.$emit('shown');
  };

  const hideDropdown = () => {
    findDropdown().vm.$emit('hide');
  };

  const createComponent = ({
    canUpdate = true,
    iteration = mockIterationWidgetResponse,
    searchQueryHandler = successSearchQueryHandler,
    mutationHandler = successUpdateWorkItemMutationHandler,
    queryVariables = { iid: '1' },
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemIteration, {
      apolloProvider: createMockApollo([
        [workItemByIidQuery, workItemQueryHandler],
        [workItemIterationSubscription, iterationSubscriptionHandler],
        [projectIterationsQuery, searchQueryHandler],
        [updateWorkItemMutation, mutationHandler],
      ]),
      propsData: {
        canUpdate,
        iteration,
        workItemId,
        workItemType,
        queryVariables,
        fullPath: 'test-project-path',
      },
      provide: {
        hasIterationsFeature: true,
      },
      stubs: { GlDropdown, GlSearchBoxByType },
    });
  };

  it('has "Iteration" label', () => {
    createComponent();
    expect(findInputGroup().exists()).toBe(true);

    expect(findInputGroup().attributes('label')).toBe(WorkItemIteration.i18n.ITERATION);
  });

  describe('Default text with canUpdate false and iteration value', () => {
    describe.each`
      description             | iteration                      | value
      ${'when no iteration'}  | ${null}                        | ${WorkItemIteration.i18n.NONE}
      ${'when iteration set'} | ${mockIterationWidgetResponse} | ${mockIterationWidgetResponse.title}
    `('$description', ({ iteration, value }) => {
      it(`has a value of "${value}"`, () => {
        createComponent({ canUpdate: false, iteration });

        expect(findDisabledTextSpan().text()).toBe(value);
        expect(findDropdown().exists()).toBe(false);
      });
    });
  });

  describe('Default text value when canUpdate true and no iteration set', () => {
    it(`has a value of "Add to iteration"`, () => {
      createComponent({ canUpdate: true, iteration: null });

      expect(findDropdown().props('text')).toBe(WorkItemIteration.i18n.ITERATION_PLACEHOLDER);
    });
  });

  describe('Dropdown search', () => {
    it('has the search box', () => {
      createComponent();

      expect(findSearchBox().exists()).toBe(true);
    });

    it('shows no matching results when no items', () => {
      createComponent({
        searchQueryHandler: successSearchWithNoMatchingIterations,
      });

      expect(findDropdownTextAtIndex(0).text()).toBe(WorkItemIteration.i18n.NO_MATCHING_RESULTS);
      expect(findDropdownItems()).toHaveLength(1);
      expect(findDropdownTexts()).toHaveLength(1);
    });
  });

  describe('Dropdown options', () => {
    beforeEach(() => {
      createComponent({ canUpdate: true });
    });

    it('shows the skeleton loader when the items are being fetched on click', async () => {
      showDropdown();
      await nextTick();

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('shows the iterations in dropdown when the items have finished fetching', async () => {
      showDropdown();
      await nextTick();
      await waitForPromises();

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findNoIterationDropdownItem().exists()).toBe(true);
      expect(findDropdownItems()).toHaveLength(
        groupIterationsResponse.data.workspace.attributes.nodes.length + 1,
      );
    });

    it('changes the iteration to null when clicked on no iteration', async () => {
      showDropdown();
      findFirstDropdownItem().vm.$emit('click');

      hideDropdown();
      await nextTick();
      expect(findDropdown().props('loading')).toBe(true);

      await waitForPromises();

      expect(findDropdown().props('loading')).toBe(false);
      expect(findDropdown().props('text')).toBe(WorkItemIteration.i18n.ITERATION_PLACEHOLDER);
    });

    it('changes the iteration to the selected iteration', async () => {
      const iterationIndex = 1;
      /** the index is -1 since no matching results is also a dropdown item */
      const iterationAtIndex =
        groupIterationsResponse.data.workspace.attributes.nodes[iterationIndex - 1];
      showDropdown();

      await waitForPromises();
      findDropdownItemAtIndex(iterationIndex).vm.$emit('click');

      hideDropdown();
      await nextTick();

      await waitForPromises();

      expect(findDropdown().props('text')).toBe(
        iterationAtIndex.title || getIterationPeriod(iterationAtIndex),
      );
    });
  });

  describe('Error handlers', () => {
    it.each`
      errorType          | expectedErrorMessage                                                 | mockValue                              | resolveFunction
      ${'graphql error'} | ${'Something went wrong while updating the task. Please try again.'} | ${updateWorkItemMutationErrorResponse} | ${'mockResolvedValue'}
      ${'network error'} | ${'Something went wrong while updating the task. Please try again.'} | ${networkResolvedValue}                | ${'mockRejectedValue'}
    `(
      'emits an error when there is a $errorType',
      async ({ mockValue, expectedErrorMessage, resolveFunction }) => {
        createComponent({
          mutationHandler: jest.fn()[resolveFunction](mockValue),
          canUpdate: true,
        });

        showDropdown();
        findFirstDropdownItem().vm.$emit('click');
        hideDropdown();

        await waitForPromises();

        expect(wrapper.emitted('error')).toEqual([[expectedErrorMessage]]);
      },
    );
  });

  describe('Tracking event', () => {
    it('tracks updating the iteration', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      createComponent({ canUpdate: true });

      showDropdown();
      findFirstDropdownItem().vm.$emit('click');
      hideDropdown();

      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_iteration', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_iteration',
        property: 'type_Task',
      });
    });
  });

  it('calls the work item query', async () => {
    createComponent();
    await waitForPromises();

    expect(workItemQueryHandler).toHaveBeenCalled();
  });

  it('skips calling the work item query when missing queryVariables', async () => {
    createComponent({ queryVariables: {} });
    await waitForPromises();

    expect(workItemQueryHandler).not.toHaveBeenCalled();
  });
});
