import { mount, createLocalVue } from '@vue/test-utils';
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

const defaultInitialStoreData = {
  availablePlans: JSON.stringify(availablePlans),
  groupData: JSON.stringify(groupData),
  planId: 'secondPlanId',
  namespaceId: null,
  setupForCompany: 'true',
  fullName: 'Full Name',
};

describe('Subscription Details', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);
  localVue.use(VueApollo);

  let wrapper;

  function createComponent(options = {}) {
    const { apolloProvider, store } = options;
    return mount(Component, {
      localVue,
      store,
      apolloProvider,
      stubs: {
        Step,
      },
    });
  }

  const organizationNameInput = () => wrapper.find({ ref: 'organization-name' });
  const groupSelect = () => wrapper.find({ ref: 'group-select' });
  const numberOfUsersInput = () => wrapper.find({ ref: 'number-of-users' });
  const companyLink = () => wrapper.find({ ref: 'company-link' });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('A new user setting up for personal use', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS);
      const store = createStore(defaultInitialStoreData);
      store.state.isNewUser = true;
      store.state.isSetupForCompany = false;
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
      const store = createStore(defaultInitialStoreData);
      store.state.isNewUser = true;
      store.state.groupData = [];
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
      const store = createStore(defaultInitialStoreData);
      store.state.isNewUser = false;
      store.state.groupData = [];
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
      store = createStore(defaultInitialStoreData);
      store.state.isNewUser = false;
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

  describe('An existing user coming from group billing page', () => {
    let store;

    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS);
      store = createStore({ ...defaultInitialStoreData, namespaceId: '132' });
      store.state.isNewUser = false;
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

  describe('validations', () => {
    const isStepValid = () => wrapper.findComponent(Step).props('isValid');
    let store;

    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS);
      store = createStore(defaultInitialStoreData);
      wrapper = createComponent({ apolloProvider: mockApollo, store });
    });

    describe('when setting up for a company', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, true);
        store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');
        store.commit(types.UPDATE_ORGANIZATION_NAME, 'Organization name');
        store.commit(types.UPDATE_SELECTED_GROUP, 483);
        store.commit(types.UPDATE_NUMBER_OF_USERS, 14);
      });

      it('should be valid', () => {
        expect(isStepValid()).toBe(true);
      });

      it('should be invalid when no plan is selected', () => {
        store.commit(types.UPDATE_SELECTED_PLAN, null);

        return localVue.nextTick().then(() => {
          expect(isStepValid()).toBe(false);
        });
      });

      it('should be invalid when no organization name is given, and no group is selected', () => {
        store.commit(types.UPDATE_ORGANIZATION_NAME, null);
        store.commit(types.UPDATE_SELECTED_GROUP, null);

        return localVue.nextTick().then(() => {
          expect(isStepValid()).toBe(false);
        });
      });

      it('should be invalid when number of users is 0', () => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 0);

        return localVue.nextTick().then(() => {
          expect(isStepValid()).toBe(false);
        });
      });

      it('should be invalid when number of users is smaller than the selected group users', () => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 10);

        return localVue.nextTick().then(() => {
          expect(isStepValid()).toBe(false);
        });
      });
    });

    describe('when not setting up for a company', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, false);
        store.commit(types.UPDATE_NUMBER_OF_USERS, 1);
      });

      it('should be valid', () => {
        expect(isStepValid()).toBe(true);
      });

      it('should be invalid when no plan is selected', () => {
        store.commit(types.UPDATE_SELECTED_PLAN, null);

        return localVue.nextTick().then(() => {
          expect(isStepValid()).toBe(false);
        });
      });

      it('should be invalid when no number of users is 0', () => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 0);

        return localVue.nextTick().then(() => {
          expect(isStepValid()).toBe(false);
        });
      });

      it('should be invalid when no number of users is greater than 1', () => {
        store.commit(types.UPDATE_NUMBER_OF_USERS, 2);

        return localVue.nextTick().then(() => {
          expect(isStepValid()).toBe(false);
        });
      });
    });
  });

  describe('Showing summary', () => {
    let store;

    beforeEach(() => {
      const mockApollo = createMockApolloProvider(STEPS, 1);
      store = createStore(defaultInitialStoreData);
      store.commit(types.UPDATE_IS_SETUP_FOR_COMPANY, true);
      store.commit(types.UPDATE_SELECTED_PLAN, 'firstPlanId');
      store.commit(types.UPDATE_ORGANIZATION_NAME, 'My Organization');
      store.commit(types.UPDATE_NUMBER_OF_USERS, 25);
      wrapper = createComponent({ apolloProvider: mockApollo, store });
    });

    it('should show the selected plan', () => {
      expect(wrapper.find({ ref: 'summary-line-1' }).text()).toEqual('Bronze plan');
    });

    it('should show the entered group name', () => {
      expect(wrapper.find({ ref: 'summary-line-2' }).text()).toEqual('Group: My Organization');
    });

    it('should show the entered number of users', () => {
      expect(wrapper.find({ ref: 'summary-line-3' }).text()).toEqual('Users: 25');
    });

    describe('selecting an existing group', () => {
      beforeEach(() => {
        store.commit(types.UPDATE_SELECTED_GROUP, 483);
      });

      it('should show the selected group name', () => {
        expect(wrapper.find({ ref: 'summary-line-2' }).text()).toEqual('Group: My second group');
      });
    });
  });
});
