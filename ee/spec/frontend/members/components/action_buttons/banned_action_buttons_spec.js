import { GlButton, GlForm } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import BannedActionButtons from 'ee/members/components/action_buttons/banned_action_buttons.vue';
import { MEMBER_TYPES } from '~/members/constants';
import { bannedMember as member } from '../../mock_data';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

Vue.use(Vuex);

describe('BannedActionButtons', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.banned]: {
          namespaced: true,
          state: {
            memberPath: '/groups/foo-bar/-/group_members/:id',
            ...state,
          },
        },
      },
    });
  };

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(BannedActionButtons, {
      store: createStore(),
      provide: {
        namespace: MEMBER_TYPES.banned,
      },
      propsData: {
        member,
        isCurrentUser: false,
        isInvitedUser: false,
        permissions: {},
        ...propsData,
      },
    });
  };

  const findForm = () => wrapper.find(GlForm);
  const findButton = () => findForm().find(GlButton);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when user has `canUnban` permission', () => {
    beforeEach(() => {
      createComponent({ permissions: { canUnban: true } });
    });

    it('submits the form when button is clicked', () => {
      expect(findButton().attributes('type')).toBe('submit');
    });

    it('displays form with correct action and inputs', () => {
      const form = findForm();

      expect(form.attributes('action')).toBe(`/groups/foo-bar/-/group_members/${member.id}/unban`);
      expect(form.find('input[name="_method"]').attributes('value')).toBe('put');
      expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(
        'mock-csrf-token',
      );
    });
  });

  describe('when user does not have `canUnban` permission', () => {
    beforeEach(() => {
      createComponent({ permissions: { canUnban: false } });
    });

    it('does not render unban form', () => {
      expect(findForm().exists()).toBe(false);
    });
  });
});
