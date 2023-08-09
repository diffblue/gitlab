import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import DisableTwoFactorDropdownItem from 'ee/members/components/action_dropdowns/disable_two_factor_dropdown_item.vue';
import { MEMBER_TYPES } from '~/members/constants';

Vue.use(Vuex);

describe('DisableTwoFactorDropdownItem', () => {
  let wrapper;
  const modalMessage = 'Modal message';
  const userId = 34;
  const slotText = 'dummy';

  const actions = {
    showDisableTwoFactorModal: jest.fn(),
  };

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
          namespaced: true,
          state: {
            memberPath: '/groups/foo-bar/-/group_members/:id',
            ...state,
          },
          actions,
        },
      },
    });
  };

  const createComponent = (propsData = {}, state) => {
    wrapper = shallowMount(DisableTwoFactorDropdownItem, {
      store: createStore(state),
      provide: {
        namespace: MEMBER_TYPES.user,
      },
      propsData: {
        modalMessage,
        userId,
        ...propsData,
      },
      slots: {
        default: slotText,
      },
    });
  };

  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  beforeEach(() => {
    createComponent();
  });

  it('renders text in the slot', () => {
    expect(findDropdownItem().text()).toBe(slotText);
  });

  it('calls Vuex action to show the modal to disable the two factor authentication', () => {
    findDropdownItem().vm.$emit('action');

    expect(actions.showDisableTwoFactorModal).toHaveBeenCalledWith(expect.any(Object), {
      message: modalMessage,
      userId,
    });
  });
});
