import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import { STEPS } from 'ee/subscriptions/constants';
import Component from 'ee/subscriptions/new/components/checkout/subscription_details.vue';
import { NEW_GROUP } from 'ee/subscriptions/new/constants';
import createStore from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';

const availablePlans = [
  { id: 'firstPlanId', code: 'bronze', price_per_year: 48, name: 'bronze' },
  { id: 'secondPlanId', code: 'silver', price_per_year: 228, name: 'silver' },
];

const groupData = [
  { id: 132, name: 'My first group', users: 3 },
  { id: 483, name: 'My second group', users: 12 },
];

const createDefaultInitialStoreData = (initialData) => ({
  availablePlans: JSON.stringify(availablePlans),
  groupData: JSON.stringify(groupData),
  planId: 'secondPlanId',
  namespaceId: null,
  fullName: 'Full Name',
  ...initialData,
});

describe('Subscription Details', () => {
  Vue.use(Vuex);
  Vue.use(VueApollo);

  let wrapper;

  function createComponent(options = {}) {
    const { apolloProvider, store } = options;
    return mount(Component, {
      store,
      apolloProvider,
      stubs: {
        Step,
      },
    });
  }

  const organizationNameInput = () => wrapper.findComponent({ ref: 'organization-name' });
  const groupSelect = () => wrapper.findComponent({ ref: 'group-select' });
  const numberOfUsersInput = () => wrapper.findComponent({ ref: 'number-of-users' });
  const companyLink = () => wrapper.findComponent({ ref: 'company-link' });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('A new user for which we do not have setupForCompany info', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS);
      const store = createStore(
        createDefaultInitialStoreData({ newUser: 'true', setupForCompany: '' }),
      );
      wrapper = createComponent({ apolloProvider: mockApollo, store });
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
      const mockApollo = createMockApolloProvider(STEPS);
      const store = createStore(
        createDefaultInitialStoreData({ newUser: 'true', setupForCompany: 'false' }),
      );
      wrapper = createComponent({ apolloProvider: mockApollo, store });
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

  describe('A new user setting up for a company or group', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS);
      const store = createStore(
        createDefaultInitialStoreData({
          newUser: 'true',
          groupData: '[]',
          setupForCompany: 'true',
        }),
      );
      wrapper = createComponent({ apolloProvider: mockApollo, store });
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

    it('should not show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(false);
    });
  });

  describe('An existing user without any groups', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS);
      const store = createStore(
        createDefaultInitialStoreData({
          newUser: 'false',
          groupData: '[]',
          setupForCompany: 'true',
        }),
      );
      wrapper = createComponent({ apolloProvider: mockApollo, store });
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

    it('should not show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(false);
    });
  });

  describe('An existing user with groups', () => {
    let store;

    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS);
      store = createStore(
        createDefaultInitialStoreData({
          newUser: 'false',
          setupForCompany: 'true',
        }),
      );
      wrapper = createComponent({ apolloProvider: mockApollo, store });
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

    it('should not show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(false);
    });

    describe('selecting an existing group', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_SELECTED_GROUP, 483);
      });

      it('should display the correct description', () => {
        expect(wrapper.text()).toContain('Your subscription will be applied to this group');
      });

      it('should set the min number of users to 12', () => {
        expect(numberOfUsersInput().attributes('min')).toBe('12');
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
    });
  });

  describe('An existing user for which we do not have setupForCompany info coming from group billing page', () => {
    let store;

    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS);
      store = createStore(
        createDefaultInitialStoreData({
          isNewUser: 'false',
          namespaceId: '132',
          setupForCompany: '',
        }),
      );
      wrapper = createComponent({ apolloProvider: mockApollo, store });
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

    it('should set the selected group to initial namespace id', () => {
      expect(groupSelect().element.value).toBe('132');
    });

    it('should not show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(false);
    });

    describe('selecting an existing group', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_SELECTED_GROUP, 483);
      });

      it('should display the correct description', () => {
        expect(wrapper.text()).toContain('Your subscription will be applied to this group');
      });

      it('should set the min number of users to 12', () => {
        expect(numberOfUsersInput().attributes('min')).toBe('12');
      });

      it('should set the selected group to the user selected namespace id', () => {
        expect(groupSelect().element.value).toBe('483');
      });
    });
  });

  describe('An existing user coming from group billing page', () => {
    let store;

    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS);
      store = createStore(
        createDefaultInitialStoreData({
          isNewUser: 'false',
          namespaceId: '132',
          setupForCompany: 'false',
        }),
      );
      wrapper = createComponent({ apolloProvider: mockApollo, store });
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

    it('should not show a link to change to setting up for a company', () => {
      expect(companyLink().exists()).toBe(false);
    });
  });

  describe('validations', () => {
    const isStepValid = () => wrapper.findComponent(Step).props('isValid');
    let store;

    describe('when setting up for a company', () => {
      beforeEach(() => {
        const mockApollo = createMockApolloProvider(STEPS);
        store = createStore(
          createDefaultInitialStoreData({
            namespaceId: 483,
            newUser: 'true',
            setupForCompany: 'true',
          }),
        );
        wrapper = createComponent({ apolloProvider: mockApollo, store });
        store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');
        store.commit(types.UPDATE_ORGANIZATION_NAME, 'Organization name');
        store.commit(types.UPDATE_NUMBER_OF_USERS, 14);
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
        const mockApollo = createMockApolloProvider(STEPS);
        store = createStore(
          createDefaultInitialStoreData({
            namespaceId: 111,
            newUser: 'true',
            setupForCompany: 'false',
            groupData: JSON.stringify([{ id: 111, name: 'Just me group', users: 1 }]),
          }),
        );
        wrapper = createComponent({ apolloProvider: mockApollo, store });
      });

      it('should disable the number of users input field', () => {
        expect(numberOfUsersInput().attributes('disabled')).toBeDefined();
      });

      it('should be valid', () => {
        expect(isStepValid()).toBe(true);
      });
    });

    describe('when not setting up for a company and not a new user', () => {
      beforeEach(() => {
        const mockApollo = createMockApolloProvider(STEPS);
        store = createStore(
          createDefaultInitialStoreData({
            namespaceId: 132,
            newUser: 'false',
            setupForCompany: 'false',
          }),
        );
        wrapper = createComponent({ apolloProvider: mockApollo, store });
        store.commit(types.UPDATE_NUMBER_OF_USERS, 3);
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
      const mockApollo = createMockApolloProvider(STEPS, 1);
      store = createStore(createDefaultInitialStoreData());
      store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, true);
      store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');
      store.commit(types.UPDATE_ORGANIZATION_NAME, 'My Organization');
      store.commit(types.UPDATE_NUMBER_OF_USERS, 25);
      wrapper = createComponent({ apolloProvider: mockApollo, store });
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
      beforeEach(() => {
        store.commit(types.UPDATE_SELECTED_GROUP, 483);
      });

      it('should show the selected group name', () => {
        expect(wrapper.findComponent({ ref: 'summary-line-2' }).text()).toEqual(
          'Group: My second group',
        );
      });
    });
  });
});
