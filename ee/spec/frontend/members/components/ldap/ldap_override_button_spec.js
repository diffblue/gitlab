import { GlButton } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import LdapOverrideButton from 'ee/members/components/ldap/ldap_override_button.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { member } from 'jest/members/mock_data';
import { MEMBER_TYPES } from '~/members/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('LdapOverrideButton', () => {
  let wrapper;
  let actions;

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
    wrapper = mount(LdapOverrideButton, {
      localVue,
      propsData: {
        member,
        ...propsData,
      },
      store: createStore(),
      provide: {
        namespace: MEMBER_TYPES.user,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays a tooltip', () => {
    const button = findButton();

    expect(getBinding(button.element, 'gl-tooltip')).not.toBeUndefined();
    expect(button.attributes('title')).toBe('Edit permissions');
  });

  it('sets `aria-label` attribute', () => {
    expect(findButton().attributes('aria-label')).toBe('Edit permissions');
  });

  it('calls Vuex action to open LDAP override confirmation modal when clicked', () => {
    findButton().trigger('click');

    expect(actions.showLdapOverrideConfirmationModal).toHaveBeenCalledWith(
      expect.any(Object),
      member,
    );
  });
});
