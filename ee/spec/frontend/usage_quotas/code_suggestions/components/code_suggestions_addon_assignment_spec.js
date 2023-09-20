import { shallowMount } from '@vue/test-utils';
import { GlToggle } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CodeSuggestionsAddonAssignment from 'ee/usage_quotas/code_suggestions/components/code_suggestions_addon_assignment.vue';
import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/code_suggestions/constants';
import userAddOnAssignmentCreateMutation from 'ee/usage_quotas/add_on/graphql/user_add_on_assignment_create.mutation.graphql';
import userAddOnAssignmentRemoveMutation from 'ee/usage_quotas/add_on/graphql/user_add_on_assignment_remove.mutation.graphql';

Vue.use(VueApollo);

describe('CodeSuggestionsAddonAssignment', () => {
  let wrapper;

  const userId = 'gid://gitlab/User/1';
  const addOnPurchaseId = 'gid://gitlab/GitlabSubscriptions::AddOnPurchase/2';
  const codeSuggestionsAddOn = { addOnPurchase: { name: ADD_ON_CODE_SUGGESTIONS } };
  const addOnPurchase = {
    id: addOnPurchaseId,
    name: ADD_ON_CODE_SUGGESTIONS,
    purchasedQuantity: 3,
    assignedQuantity: 2,
  };
  const addOnAssignmentSuccess = { clientMutationId: '1', errors: [], addOnPurchase };
  const knownAddOnAssignmentError = {
    clientMutationId: '1',
    errors: ['NO_SEATS_AVAILABLE'],
    addOnPurchase,
  };
  const unknownAddOnAssignmentError = {
    clientMutationId: '1',
    errors: ['AN_ERROR'],
    addOnPurchase,
  };
  const nonStringAddOnAssignmentError = {
    clientMutationId: '1',
    errors: [null],
    addOnPurchase,
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

  const createComponent = ({
    props = {},
    addonAssignmentCreateHandler = assignAddOnHandler,
    addOnAssignmentRemoveHandler = unassignAddOnHandler,
  }) => {
    wrapper = shallowMount(CodeSuggestionsAddonAssignment, {
      apolloProvider: createMockApolloProvider(
        addonAssignmentCreateHandler,
        addOnAssignmentRemoveHandler,
      ),
      propsData: {
        addOnAssignments: [],
        userId,
        addOnPurchaseId,
        ...props,
      },
    });
  };

  const findToggle = () => wrapper.findComponent(GlToggle);

  describe.each([
    {
      title: 'when there are assigned add-ons',
      addOnAssignments: [codeSuggestionsAddOn],
      toggleProps: { disabled: false, value: true },
    },
    {
      title: 'when there are no assigned add-ons',
      addOnAssignments: [],
      toggleProps: { disabled: false, value: false },
    },
  ])('$title', ({ addOnAssignments, toggleProps }) => {
    beforeEach(() => {
      createComponent({ props: { addOnAssignments } });
    });

    it('renders addon toggle with appropriate props', () => {
      expect(findToggle().props()).toEqual(expect.objectContaining(toggleProps));
    });
  });

  describe('when assigning an addon', () => {
    beforeEach(() => {
      createComponent({
        props: { addOnAssignments: [] },
      });
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
          userId,
        },
      });
    });

    it('does not call addon un-assigment mutation', () => {
      expect(unassignAddOnHandler).not.toHaveBeenCalled();
    });
  });

  describe('when error occurs while assigning add-on', () => {
    const addOnAssignments = [];

    it('emits an event with the error code from response for a known error', async () => {
      createComponent({
        props: { addOnAssignments },
        addonAssignmentCreateHandler: jest
          .fn()
          .mockResolvedValue({ data: { userAddOnAssignmentCreate: knownAddOnAssignmentError } }),
      });
      findToggle().vm.$emit('change', true);

      await waitForPromises();

      expect(wrapper.emitted('handleAddOnAssignmentError')).toEqual([['NO_SEATS_AVAILABLE']]);
    });

    it('emits an event with generic error code for a non string error code', async () => {
      createComponent({
        props: { addOnAssignments },
        addonAssignmentCreateHandler: jest.fn().mockResolvedValue({
          data: { userAddOnAssignmentCreate: nonStringAddOnAssignmentError },
        }),
      });
      findToggle().vm.$emit('change', true);

      await waitForPromises();

      expect(wrapper.emitted('handleAddOnAssignmentError')).toEqual([['CANNOT_ASSIGN_ADDON']]);
    });

    it('emits an event with generic error code for an unknown error', async () => {
      createComponent({
        props: { addOnAssignments },
        addonAssignmentCreateHandler: jest
          .fn()
          .mockResolvedValue({ data: { userAddOnAssignmentCreate: unknownAddOnAssignmentError } }),
      });
      findToggle().vm.$emit('change', true);

      await waitForPromises();

      expect(wrapper.emitted('handleAddOnAssignmentError')).toEqual([['CANNOT_ASSIGN_ADDON']]);
    });

    it('emits an event with the generic error code', async () => {
      createComponent({
        props: { addOnAssignments },
        addonAssignmentCreateHandler: jest.fn().mockRejectedValue(new Error('An error')),
      });
      findToggle().vm.$emit('change', true);

      await waitForPromises();

      expect(wrapper.emitted('handleAddOnAssignmentError')).toEqual([['CANNOT_ASSIGN_ADDON']]);
    });
  });

  describe('when un-assigning an addon', () => {
    beforeEach(() => {
      createComponent({
        props: { addOnAssignments: [codeSuggestionsAddOn] },
      });
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
          userId,
        },
      });
    });

    it('does not call addon assigment mutation', () => {
      expect(assignAddOnHandler).not.toHaveBeenCalled();
    });
  });

  describe('when error occurs while un-assigning add-on', () => {
    const addOnAssignments = [codeSuggestionsAddOn];

    it('emits an event with the error code from response for a known error', async () => {
      createComponent({
        props: { addOnAssignments },
        addOnAssignmentRemoveHandler: jest
          .fn()
          .mockResolvedValue({ data: { userAddOnAssignmentRemove: knownAddOnAssignmentError } }),
      });
      findToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(wrapper.emitted('handleAddOnAssignmentError')).toEqual([['NO_SEATS_AVAILABLE']]);
    });

    it('emits an event with generic error code for a non string error code', async () => {
      createComponent({
        props: { addOnAssignments },
        addOnAssignmentRemoveHandler: jest.fn().mockResolvedValue({
          data: { userAddOnAssignmentRemove: nonStringAddOnAssignmentError },
        }),
      });
      findToggle().vm.$emit('change', true);

      await waitForPromises();

      expect(wrapper.emitted('handleAddOnAssignmentError')).toEqual([['CANNOT_UNASSIGN_ADDON']]);
    });

    it('emits an event with generic error code for an unknown error', async () => {
      createComponent({
        props: { addOnAssignments },
        addOnAssignmentRemoveHandler: jest
          .fn()
          .mockResolvedValue({ data: { userAddOnAssignmentRemove: unknownAddOnAssignmentError } }),
      });
      findToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(wrapper.emitted('handleAddOnAssignmentError')).toEqual([['CANNOT_UNASSIGN_ADDON']]);
    });

    it('emits an event with the generic error code', async () => {
      createComponent({
        props: { addOnAssignments },
        addOnAssignmentRemoveHandler: jest.fn().mockRejectedValue(new Error('An error')),
      });
      findToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(wrapper.emitted('handleAddOnAssignmentError')).toEqual([['CANNOT_UNASSIGN_ADDON']]);
    });
  });
});
