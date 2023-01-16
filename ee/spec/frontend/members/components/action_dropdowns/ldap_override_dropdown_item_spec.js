import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import LdapOverrideDropdownItem from 'ee/members/components/action_dropdowns/ldap_override_dropdown_item.vue';
import { member } from 'jest/members/mock_data';
import { MEMBER_TYPES } from '~/members/constants';

Vue.use(Vuex);

describe('LdapOverrideDropdownItem', () => {
  let wrapper;
  let actions;
  const text = 'dummy';

  const createStore = () => {
    actions = {
      showLdapOverrideConfirmationModal: jest.fn(),
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
    wrapper = shallowMount(LdapOverrideDropdownItem, {
      propsData: {
        member,
        ...propsData,
      },
      store: createStore(),
      provide: {
        namespace: MEMBER_TYPES.user,
      },
      slots: {
        default: text,
      },
    });
  };

  const findDropdownItem = () => wrapper.findComponent(GlDropdownItem);

  beforeEach(() => {
    createComponent();
  });

  it('renders a slot', () => {
    expect(findDropdownItem().html()).toContain(text);
  });

  it('calls Vuex action to open LDAP override confirmation modal when clicked', () => {
    findDropdownItem().vm.$emit('click');

    expect(actions.showLdapOverrideConfirmationModal).toHaveBeenCalledWith(
      expect.any(Object),
      member,
    );
  });
});
