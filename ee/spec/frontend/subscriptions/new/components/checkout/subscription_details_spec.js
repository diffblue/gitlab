import Vue, { nextTick } from 'vue';
import { GlLink } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import { mockTracking } from 'helpers/tracking_helper';
import { QSR_RECONCILIATION_PATH, STEPS } from 'ee/subscriptions/constants';
import Component from 'ee/subscriptions/new/components/checkout/subscription_details.vue';
import { PurchaseEvent, NEW_GROUP } from 'ee/subscriptions/new/constants';
import createStore from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import getBillableMembersCountQuery from 'ee/subscriptions/graphql/queries/billable_members_count.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { mockInvoicePreviewBronze } from 'ee_jest/subscriptions/mock_data';

jest.mock('~/lib/logger');

const availablePlans = [
  { id: 'firstPlanId', code: 'bronze', price_per_year: 48, name: 'bronze' },
  { id: 'secondPlanId', code: 'silver', price_per_year: 228, name: 'silver' },
];
const firstGroup = { id: 132, name: 'My first group', full_path: 'my-first-group' };
const secondGroup = { id: 483, name: 'My second group', full_path: 'my-second-group' };
const groupData = [firstGroup, secondGroup];
const createDefaultInitialStoreData = (initialData) => ({
  availablePlans: JSON.stringify(availablePlans),
  groupData: JSON.stringify(groupData),
  planId: 'secondPlanId',
  namespaceId: null,
  fullName: 'Full Name',
  ...initialData,
});
const defaultBillableMembersCountMock = jest.fn().mockResolvedValue({
  data: {
    group: {
      id: secondGroup.id,
      enforceFreeUserCap: false,
      billableMembersCount: 3,
    },
  },
});

describe('Subscription Details', () => {
  Vue.use(Vuex);
  Vue.use(VueApollo);

  let wrapper;

  function createComponent(options = {}) {
    const { store, billableMembersCountMock } = options;
    const mockHandler = billableMembersCountMock || defaultBillableMembersCountMock;
    const handlers = [[getBillableMembersCountQuery, mockHandler]];
    const apolloProvider = createMockApolloProvider(STEPS, 1, {}, handlers);

    wrapper = mountExtended(Component, {
      store,
      apolloProvider,
      stubs: {
        Step,
      },
    });

    return waitForPromises();
  }

  const organizationNameInput = () => wrapper.findComponent({ ref: 'organization-name' });
  const groupSelect = () => wrapper.findComponent({ ref: 'group-select' });
  const numberOfUsersInput = () => wrapper.findComponent({ ref: 'number-of-users' });
  const companyLink = () => wrapper.findComponent({ ref: 'company-link' });
  const findQsrOverageMessage = () => wrapper.findByTestId('qsr-overage-message');
  const findNumberOfUsersFormGroup = () => wrapper.findByTestId('number-of-users-field');

  describe('when rendering', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS, 1, {}, []);
      const store = createStore(
        createDefaultInitialStoreData({ newUser: 'true', setupForCompany: '' }),
      );
      return createComponent({ apolloProvider: mockApollo, store });
    });

    it('has an alert displaying a message related to QSR process', () => {
      expect(findQsrOverageMessage().text()).toMatchInterpolatedText(
        'You are billed if you exceed this number. How does billing work?',
      );
    });

    it('has a link to QSR process help page', () => {
      expect(findQsrOverageMessage().findComponent(GlLink).attributes('href')).toMatch(
        QSR_RECONCILIATION_PATH,
      );
    });
  });

  describe('A new user for which we do not have setupForCompany info', () => {
    beforeEach(() => {
      const store = createStore(
        createDefaultInitialStoreData({ newUser: 'true', setupForCompany: '' }),
      );
      return createComponent({ store });
    });

    it('should not display an input field for the company or group name', () => {
      expect(organizationNameInput().exists()).toBe(false);
    });

    it('should not display the group select', () => {
      expect(groupSelect().exists()).toBe(false);
    });

    it('should disable the number of users input field', () => {
      expect(numberOfUsersInput().attributes('disabled')).toBeDefined();
    });

    it('should set the min number of users to 1', () => {
      expect(numberOfUsersInput().attributes('min')).toBe('1');
    });

    it('should show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(true);
    });
  });

  describe('A new user setting up for personal use', () => {
    beforeEach(() => {
      const store = createStore(
        createDefaultInitialStoreData({ newUser: 'true', setupForCompany: 'false' }),
      );
      return createComponent({ store });
    });

    it('should not display an input field for the company or group name', () => {
      expect(organizationNameInput().exists()).toBe(false);
    });

    it('should not display the group select', () => {
      expect(groupSelect().exists()).toBe(false);
    });

    it('should disable the number of users input field', () => {
      expect(numberOfUsersInput().attributes('disabled')).toBeDefined();
    });

    it('should set the min number of users to 1', () => {
      expect(numberOfUsersInput().attributes('min')).toBe('1');
    });

    it('should not show the label description with minimum number of users', () => {
      expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(null);
    });

    it('should show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(true);
    });
  });

  describe('A new user setting up for a company or group', () => {
    beforeEach(() => {
      const store = createStore(
        createDefaultInitialStoreData({
          newUser: 'true',
          groupData: '[]',
          setupForCompany: 'true',
        }),
      );
      return createComponent({ store });
    });

    it('should display an input field for the company or group name', () => {
      expect(organizationNameInput().exists()).toBe(true);
    });

    it('should not display the group select', () => {
      expect(groupSelect().exists()).toBe(false);
    });

    it('should enable the number of users input field', () => {
      expect(numberOfUsersInput().attributes('disabled')).toBeUndefined();
    });

    it('should set the min number of users to 1', () => {
      expect(numberOfUsersInput().attributes('min')).toBe('1');
    });

    it('should not show the label description with minimum number of users', () => {
      expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(null);
    });

    it('should not show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(false);
    });
  });

  describe('An existing user without any groups', () => {
    beforeEach(() => {
      const store = createStore(
        createDefaultInitialStoreData({
          newUser: 'false',
          groupData: '[]',
          setupForCompany: 'true',
        }),
      );
      return createComponent({ store });
    });

    it('should display an input field for the company or group name', () => {
      expect(organizationNameInput().exists()).toBe(true);
    });

    it('should not display the group select', () => {
      expect(groupSelect().exists()).toBe(false);
    });

    it('should enable the number of users input field', () => {
      expect(numberOfUsersInput().attributes('disabled')).toBeUndefined();
    });

    it('should set the min number of users to 1', () => {
      expect(numberOfUsersInput().attributes('min')).toBe('1');
    });

    it('should not show the label description with minimum number of users', () => {
      expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(null);
    });

    it('should not show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(false);
    });
  });

  describe('An existing user with groups', () => {
    let store;

    beforeEach(() => {
      const billableMembersCountMock = jest.fn().mockResolvedValue({
        data: {
          group: {
            id: secondGroup.id,
            enforceFreeUserCap: false,
            billableMembersCount: 12,
          },
        },
      });

      store = createStore(
        createDefaultInitialStoreData({
          newUser: 'false',
          setupForCompany: 'true',
        }),
      );
      return createComponent({ store, billableMembersCountMock });
    });

    it('should not display an input field for the company or group name', () => {
      expect(organizationNameInput().exists()).toBe(false);
    });

    it('should display the group select', () => {
      expect(groupSelect().exists()).toBe(true);
    });

    it('should enable the number of users input field', () => {
      expect(numberOfUsersInput().attributes('disabled')).toBeUndefined();
    });

    it('should set the min number of users to 1', () => {
      expect(numberOfUsersInput().attributes('min')).toBe('1');
    });

    it('should not show the label description with minimum number of users', () => {
      expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(null);
    });

    it('should not show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(false);
    });

    describe('selecting an existing group', () => {
      beforeEach(async () => {
        store.commit(types.UPDATE_SELECTED_GROUP, secondGroup.id);
        await waitForPromises();
        return nextTick();
      });

      it('should display the correct description', () => {
        expect(wrapper.text()).toContain('Your subscription will be applied to this group');
      });

      it('should set the min number of users to 12', () => {
        expect(numberOfUsersInput().attributes('min')).toBe('12');
      });

      it('should set the label description with minimum number of users', () => {
        expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(
          'Must be 12 (your seats in use) or more.',
        );
      });
    });

    describe('when enforceFreeUserCap is true', () => {
      beforeEach(async () => {
        const billableMembersCountMock = jest.fn().mockResolvedValue({
          data: {
            group: {
              id: secondGroup.id,
              enforceFreeUserCap: true,
              billableMembersCount: 12,
            },
          },
        });

        store = createStore(
          createDefaultInitialStoreData({
            newUser: 'false',
            setupForCompany: 'true',
          }),
        );
        createComponent({ store, billableMembersCountMock });

        store.commit(types.UPDATE_SELECTED_GROUP, secondGroup.id);
        await nextTick();
      });

      it('should set the label description', () => {
        expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(
          'Must be 12 (your seats in use, plus all over limit members) or more. To buy fewer seats, remove members from the group.',
        );
      });
    });

    describe('selecting "Create a new group', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_SELECTED_GROUP, NEW_GROUP);
      });

      it('should display the correct description', () => {
        expect(wrapper.text()).toContain("You'll create your new group after checkout");
      });

      it('should display an input field for the company or group name', () => {
        expect(organizationNameInput().exists()).toBe(true);
      });

      it('should set the min number of users to 1', () => {
        expect(numberOfUsersInput().attributes('min')).toBe('1');
      });

      it('should not show the label description with minimum number of users', () => {
        expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(null);
      });
    });
  });

  describe('An existing user for which we do not have setupForCompany info coming from group billing page', () => {
    let store;
    const billableMembersCountMock = jest.fn();

    beforeEach(() => {
      billableMembersCountMock.mockResolvedValue({
        data: { group: { id: firstGroup.id, billableMembersCount: 3, enforceFreeUserCap: false } },
      });
      store = createStore(
        createDefaultInitialStoreData({
          isNewUser: 'false',
          namespaceId: firstGroup.id,
          setupForCompany: '',
        }),
      );
      return createComponent({ store, billableMembersCountMock });
    });

    it('should not display an input field for the company or group name', () => {
      expect(organizationNameInput().exists()).toBe(false);
    });

    it('should display the group select', () => {
      expect(groupSelect().exists()).toBe(true);
    });

    it('should enable the number of users input field', () => {
      expect(numberOfUsersInput().attributes('disabled')).toBeUndefined();
    });

    it('should set the min number of users to 3', () => {
      expect(numberOfUsersInput().attributes('min')).toBe('3');
    });

    it('should set the label description with minimum number of users', () => {
      expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(
        'Must be 3 (your seats in use) or more.',
      );
    });

    it('should call the query with appropriate params', () => {
      expect(billableMembersCountMock).toHaveBeenCalledWith({
        fullPath: firstGroup.full_path,
        requestedHostedPlan: 'silver',
      });
    });

    it('should set the selected group to initial namespace id', () => {
      expect(groupSelect().element.value).toBe(firstGroup.id.toString());
    });

    it('should not show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(false);
    });

    describe('selecting an existing group', () => {
      beforeEach(() => {
        billableMembersCountMock.mockResolvedValue({
          data: {
            group: { id: secondGroup.id, billableMembersCount: 12, enforceFreeUserCap: false },
          },
        });
        store.commit(types.UPDATE_SELECTED_GROUP, secondGroup.id);
        return waitForPromises();
      });

      it('should display the correct description', () => {
        expect(wrapper.text()).toContain('Your subscription will be applied to this group');
      });

      it('should set the min number of users to 12', () => {
        expect(numberOfUsersInput().attributes('min')).toBe('12');
      });

      it('should set the label description with minimum number of users', () => {
        expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(
          'Must be 12 (your seats in use) or more.',
        );
      });

      it('should set the selected group to the user selected namespace id', () => {
        expect(groupSelect().element.value).toBe(secondGroup.id.toString());
      });
    });
  });

  describe('An existing user coming from group billing page', () => {
    let store;

    beforeEach(() => {
      store = createStore(
        createDefaultInitialStoreData({
          isNewUser: 'false',
          namespaceId: firstGroup.id,
          setupForCompany: 'false',
        }),
      );
      return createComponent({ store });
    });

    it('should not display an input field for the company or group name', () => {
      expect(organizationNameInput().exists()).toBe(false);
    });

    it('should display the group select', () => {
      expect(groupSelect().exists()).toBe(true);
    });

    it('should enable the number of users input field', () => {
      expect(numberOfUsersInput().attributes('disabled')).toBeUndefined();
    });

    it('should set the label description with minimum number of users', () => {
      expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(
        'Must be 3 (your seats in use) or more.',
      );
    });

    it('should not show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(false);
    });
  });

  describe('tracking', () => {
    let store;

    beforeEach(async () => {
      store = createStore(
        createDefaultInitialStoreData({
          isNewUser: 'false',
          namespaceId: firstGroup.id,
          setupForCompany: 'false',
        }),
      );
      await createComponent({ store });
      store.commit(types.UPDATE_NUMBER_OF_USERS, 13);
    });

    it('tracks completion details', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      wrapper.findComponent(Step).vm.$emit('nextStep');
      await nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'update_plan_type',
        property: 'silver',
      });
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'update_seat_count',
        property: 13,
      });
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'update_group',
        property: firstGroup.id,
      });
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'continue_billing',
      });
    });

    it('tracks step edits', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      wrapper.findComponent(Step).vm.$emit('stepEdit', 'stepID');
      await nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'edit',
        property: 'subscriptionDetails',
      });
    });
  });

  describe('validations', () => {
    const isStepValid = () => wrapper.findComponent(Step).props('isValid');
    let store;

    describe('when setting up for a company', () => {
      beforeEach(async () => {
        const billableMembersCountMock = jest.fn().mockResolvedValue({
          data: {
            group: { id: secondGroup.id, billableMembersCount: 12, enforceFreeUserCap: false },
          },
        });
        store = createStore(
          createDefaultInitialStoreData({
            namespaceId: secondGroup.id,
            newUser: 'true',
            setupForCompany: 'true',
          }),
        );
        await createComponent({ store, billableMembersCountMock });
        store.commit(types.UPDATE_ORGANIZATION_NAME, 'Organization name');
        store.commit(types.UPDATE_NUMBER_OF_USERS, 14);
        store.commit(types.UPDATE_INVOICE_PREVIEW, mockInvoicePreviewBronze.data.invoicePreview);
        await nextTick();
      });

      it('should be valid', () => {
        expect(isStepValid()).toBe(true);
      });

      it('should be invalid when no plan is selected', async () => {
        store.commit(types.UPDATE_SELECTED_PLAN, null);

        await nextTick();

        expect(isStepValid()).toBe(false);
      });

      it('should be invalid when no organization name is given, and no group is selected', async () => {
        store.commit(types.UPDATE_ORGANIZATION_NAME, null);
        store.commit(types.UPDATE_SELECTED_GROUP, null);

        await nextTick();

        expect(isStepValid()).toBe(false);
      });

      it('should be invalid when number of users is 0', async () => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 0);

        await nextTick();

        expect(isStepValid()).toBe(false);
      });

      it('should be invalid when number of users is smaller than the selected group users', async () => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 10);

        await nextTick();

        expect(isStepValid()).toBe(false);
      });
    });

    describe('when not setting up for a company and a new user', () => {
      beforeEach(() => {
        const mockApollo = createMockApolloProvider(STEPS, 1, {}, []);
        store = createStore(
          createDefaultInitialStoreData({
            namespaceId: 111,
            newUser: 'true',
            setupForCompany: 'false',
            groupData: JSON.stringify([{ id: 111, name: 'Just me group', users: 1 }]),
          }),
        );
        store.commit(types.UPDATE_INVOICE_PREVIEW, mockInvoicePreviewBronze.data.invoicePreview);
        return createComponent({ apolloProvider: mockApollo, store });
      });

      it('should disable the number of users input field', () => {
        expect(numberOfUsersInput().attributes('disabled')).toBeDefined();
      });

      it('should not show the label description with minimum number of users', () => {
        expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(null);
      });

      it('should be valid', () => {
        expect(isStepValid()).toBe(true);
      });
    });

    describe('when not setting up for a company and not a new user', () => {
      beforeEach(async () => {
        const billableMembersCountMock = jest.fn().mockResolvedValue({
          data: {
            group: { id: firstGroup.id, billableMembersCount: 3, enforceFreeUserCap: false },
          },
        });
        const handlers = [[getBillableMembersCountQuery, billableMembersCountMock]];
        const mockApollo = createMockApolloProvider(STEPS, 1, {}, handlers);
        store = createStore(
          createDefaultInitialStoreData({
            namespaceId: firstGroup.id,
            newUser: 'false',
            setupForCompany: 'false',
          }),
        );
        await createComponent({ apolloProvider: mockApollo, store });
        store.commit(types.UPDATE_SELECTED_GROUP, secondGroup.id);
        store.commit(types.UPDATE_INVOICE_PREVIEW, mockInvoicePreviewBronze.data.invoicePreview);
        await nextTick();
      });

      it('should be valid', () => {
        expect(isStepValid()).toBe(true);
      });

      it('should be invalid when no plan is selected', async () => {
        store.commit(types.UPDATE_SELECTED_PLAN, null);

        await nextTick();

        expect(isStepValid()).toBe(false);
      });

      it('should be invalid when number users is 0', async () => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 0);

        await nextTick();

        expect(isStepValid()).toBe(false);
      });

      it('should be valid when number of users is greater than group users', async () => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 4);

        await nextTick();
        expect(isStepValid()).toBe(true);
      });

      it('should not be valid when number of users is less than group users', async () => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 2);

        await nextTick();

        expect(isStepValid()).toBe(false);
      });
    });
  });

  describe('Showing summary', () => {
    let store;

    beforeEach(() => {
      store = createStore(createDefaultInitialStoreData());
      store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, true);
      store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');
      store.commit(types.UPDATE_ORGANIZATION_NAME, 'My Organization');
      store.commit(types.UPDATE_NUMBER_OF_USERS, 25);
      store.commit(types.UPDATE_INVOICE_PREVIEW, mockInvoicePreviewBronze.data.invoicePreview);
      return createComponent({ store });
    });

    it('should show the selected plan', () => {
      expect(wrapper.findComponent({ ref: 'summary-line-1' }).text()).toEqual('Bronze plan');
    });

    it('should show the entered group name', () => {
      expect(wrapper.findComponent({ ref: 'summary-line-2' }).text()).toEqual(
        'Group: My Organization',
      );
    });

    it('should show the entered number of users', () => {
      expect(wrapper.findComponent({ ref: 'summary-line-3' }).text()).toEqual('Users: 25');
    });

    describe('selecting an existing group', () => {
      beforeEach(async () => {
        store.commit(types.UPDATE_SELECTED_GROUP, secondGroup.id);
        store.commit(types.UPDATE_ORGANIZATION_NAME, null);
        await waitForPromises();
        await nextTick();
      });

      it('should show the selected group name', () => {
        expect(wrapper.findComponent({ ref: 'summary-line-2' }).text()).toEqual(
          'Group: My second group',
        );
      });
    });
  });

  describe('when errored', () => {
    const errorMessage = 'Oopsie, something went wrong';
    const mockError = new Error(errorMessage);

    beforeEach(() => {
      const billableMembersCountMock = jest.fn().mockRejectedValue(mockError);
      const store = createStore(createDefaultInitialStoreData());
      store.commit(types.UPDATE_SELECTED_GROUP, secondGroup.id);
      return createComponent({ store, billableMembersCountMock });
    });

    it('emits an `error` event', () => {
      expect(wrapper.emitted(PurchaseEvent.ERROR)).toEqual([[mockError]]);
    });

    it('should not show the number of users label description when in error', async () => {
      await nextTick();

      expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(null);
    });
  });

  describe('when resetting the error', () => {
    beforeEach(() => {
      const billableMembersCountMock = jest.fn().mockResolvedValue({});
      const store = createStore(createDefaultInitialStoreData());
      return createComponent({ store, billableMembersCountMock });
    });

    it('emits an `error-reset` event', () => {
      expect(wrapper.emitted(PurchaseEvent.ERROR_RESET)).toBeUndefined();
    });

    it('should not show the number of users label description when in error', async () => {
      await nextTick();

      expect(findNumberOfUsersFormGroup().props().labelDescription).toBe(null);
    });
  });

  describe('when is loading', () => {
    beforeEach(() => {
      const billableMembersCountMock = jest.fn().mockImplementation(() => new Promise(() => {}));
      const store = createStore(createDefaultInitialStoreData());
      store.commit(types.UPDATE_SELECTED_GROUP, secondGroup.id);

      return createComponent({ store, billableMembersCountMock });
    });

    it('should show loading step', () => {
      const step = wrapper.findComponent(Step);

      expect(step.props()).toMatchObject({
        isValid: false,
      });
      expect(step.find('[data-testid="subscription-loading-container"]').exists()).toBe(true);
    });
  });
});
