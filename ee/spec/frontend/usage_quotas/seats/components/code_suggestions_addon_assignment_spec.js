import { shallowMount } from '@vue/test-utils';
import { GlToggle, GlTooltip } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CodeSuggestionsAddonAssignment from 'ee/usage_quotas/seats/components/code_suggestions_addon_assignment.vue';
import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/seats/constants';
import userAddOnAssignmentCreateMutation from 'ee/usage_quotas/graphql/queries/user_addon_assignment_create.mutation.graphql';
import userAddOnAssignmentRemoveMutation from 'ee/usage_quotas/graphql/queries/user_addon_assignment_remove.mutation.graphql';

Vue.use(VueApollo);

describe('CodeSuggestionsAddonAssignment', () => {
  let wrapper;

  const userId = 1;
  const globalUserId = `gid://gitlab/User/${userId}`;
  const addOnPurchaseId = 'gid://gitlab/GitlabSubscriptions::AddOnPurchase/2';
  const codeSuggestionsAddon = { name: ADD_ON_CODE_SUGGESTIONS };
  const addOnAssignmentSuccess = {
    clientMutationId: '1',
    errors: [],
    addOnPurchase: {
      id: addOnPurchaseId,
      name: ADD_ON_CODE_SUGGESTIONS,
      purchasedQuantity: 3,
      assignedQuantity: 2,
    },
  };

  const assignAddOnHandler = jest.fn().mockResolvedValue({
    data: { userAddOnAssignmentCreate: addOnAssignmentSuccess },
  });
  const unassignAddOnHandler = jest.fn().mockResolvedValue({
    data: { userAddOnAssignmentRemove: addOnAssignmentSuccess },
  });

  const createMockApolloProvider = (addonAssignmentCreateHandler, addOnAssignmentRemoveHandler) =>
    createMockApollo([
      [userAddOnAssignmentCreateMutation, addonAssignmentCreateHandler],
      [userAddOnAssignmentRemoveMutation, addOnAssignmentRemoveHandler],
    ]);

  const createComponent = (
    props = {},
    addonAssignmentCreateHandler = assignAddOnHandler,
    addOnAssignmentRemoveHandler = unassignAddOnHandler,
  ) => {
    wrapper = shallowMount(CodeSuggestionsAddonAssignment, {
      apolloProvider: createMockApolloProvider(
        addonAssignmentCreateHandler,
        addOnAssignmentRemoveHandler,
      ),
      propsData: {
        addOns: {},
        userId,
        addOnPurchaseId,
        ...props,
      },
    });
  };

  const findToggle = () => wrapper.findComponent(GlToggle);
  const findTooltip = () => wrapper.findComponent(GlTooltip);

  const codeSuggestionsAddOn = { name: ADD_ON_CODE_SUGGESTIONS };

  const applicableAddOns = { applicable: [codeSuggestionsAddOn], assigned: [] };
  const assignedAddOns = { applicable: [codeSuggestionsAddOn], assigned: [codeSuggestionsAddOn] };
  const noAddOns = { applicable: [], assigned: [] };

  describe.each([
    {
      title: 'when there are applicable addons',
      addOns: applicableAddOns,
      toggleProps: { disabled: false, value: false },
      tooltipExists: false,
    },
    {
      title: 'when there are assigned addons',
      addOns: assignedAddOns,
      toggleProps: { disabled: false, value: true },
      tooltipExists: false,
    },
    {
      title: 'when there are no applicable addons',
      addOns: noAddOns,
      toggleProps: { disabled: true, value: false },
      tooltipExists: true,
    },
    {
      title: 'when addons is not provided',
      addOns: undefined,
      toggleProps: { disabled: true, value: false },
      tooltipExists: true,
    },
  ])('$title', ({ addOns, toggleProps, tooltipExists }) => {
    beforeEach(() => {
      createComponent({ addOns });
    });

    it('renders addon toggle with appropriate props', () => {
      expect(findToggle().props()).toEqual(expect.objectContaining(toggleProps));
    });

    it(`shows addon unavailable tooltip: ${tooltipExists}`, () => {
      expect(findTooltip().exists()).toBe(tooltipExists);
    });
  });

  describe('when assigning an addon', () => {
    beforeEach(() => {
      createComponent(
        { addOns: { applicable: [codeSuggestionsAddon], assigned: [] } },
        assignAddOnHandler,
        unassignAddOnHandler,
      );
      findToggle().vm.$emit('change', true);
    });

    it('shows loading state for the toggle', () => {
      expect(findToggle().props('isLoading')).toBe(true);
    });

    it('turns the toggle on', async () => {
      await waitForPromises();

      expect(findToggle().props('value')).toBe(true);
    });

    it('does not show loading state once updated', async () => {
      await waitForPromises();

      expect(findToggle().props('isLoading')).toBe(false);
    });

    it('calls addon assigment mutation with appropriate params', () => {
      expect(assignAddOnHandler).toHaveBeenCalledWith({
        input: {
          addOnPurchaseId,
          userId: globalUserId,
        },
      });
    });

    it('does not call addon unassigment mutation', () => {
      expect(unassignAddOnHandler).not.toHaveBeenCalled();
    });
  });

  describe('when unassigning an addon', () => {
    beforeEach(() => {
      createComponent(
        { addOns: { applicable: [codeSuggestionsAddon], assigned: [codeSuggestionsAddon] } },
        assignAddOnHandler,
        unassignAddOnHandler,
      );
      findToggle().vm.$emit('change', false);
    });

    it('shows loading state for the toggle', () => {
      expect(findToggle().props('isLoading')).toBe(true);
    });

    it('turns the toggle off', async () => {
      await waitForPromises();

      expect(findToggle().props('value')).toBe(false);
    });

    it('does not show loading state once updated', async () => {
      await waitForPromises();

      expect(findToggle().props('isLoading')).toBe(false);
    });

    it('calls addon assigment mutation with appropriate params', () => {
      expect(unassignAddOnHandler).toHaveBeenCalledWith({
        input: {
          addOnPurchaseId,
          userId: globalUserId,
        },
      });
    });

    it('does not call addon assigment mutation', () => {
      expect(assignAddOnHandler).not.toHaveBeenCalled();
    });
  });
});
