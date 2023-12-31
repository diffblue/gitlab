import { GlListboxItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import LdapDropdownFooter from 'ee/members/components/action_dropdowns/ldap_dropdown_footer.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { MEMBER_TYPES } from '~/members/constants';

Vue.use(Vuex);

describe('LdapDropdownFooter', () => {
  let wrapper;
  let actions;
  const $toast = {
    show: jest.fn(),
  };

  const createStore = () => {
    actions = {
      updateLdapOverride: jest.fn(() => Promise.resolve()),
    };

    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
          namespaced: true,
          actions,
        },
      },
    });
  };

  const createComponent = (propsData = {}) => {
    wrapper = mount(LdapDropdownFooter, {
      propsData: {
        memberId: 1,
        ...propsData,
      },
      store: createStore(),
      provide: {
        namespace: MEMBER_TYPES.user,
      },
      mocks: {
        $toast,
      },
    });
  };

  describe('when dropdown item is clicked', () => {
    beforeEach(() => {
      createComponent();

      wrapper.findComponent(GlListboxItem).trigger('click');
    });

    it('calls `updateLdapOverride` action', () => {
      expect(actions.updateLdapOverride).toHaveBeenCalledWith(expect.any(Object), {
        memberId: 1,
        override: false,
      });
    });

    it('displays toast when `updateLdapOverride` is successful', async () => {
      await waitForPromises();

      expect($toast.show).toHaveBeenCalledWith('Reverted to LDAP group sync settings.');
    });
  });
});
