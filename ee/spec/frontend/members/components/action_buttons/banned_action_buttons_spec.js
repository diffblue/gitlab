import { GlButton, GlForm } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import BannedActionButtons from 'ee/members/components/action_buttons/banned_action_buttons.vue';
import { MEMBER_TYPES } from '~/members/constants';
import { assertProps } from 'helpers/assert_props';
import { bannedMember as member } from '../../mock_data';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

Vue.use(Vuex);

const DEFAULT_MEMBERS_PATH = '/groups/foo-bar/-/group_members';

describe('BannedActionButtons', () => {
  let wrapper;

  const defaultProps = { member, isCurrentUser: false, isInvitedUser: false, permissions: {} };

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.banned]: {
          namespaced: true,
          state: {
            memberPath: `${DEFAULT_MEMBERS_PATH}/:id`,
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
        ...defaultProps,
        ...propsData,
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findButton = () => findForm().findComponent(GlButton);

  afterEach(() => {
    wrapper?.destroy();
  });

  describe('when user has `canUnban` permission', () => {
    beforeEach(() => {
      createComponent({ permissions: { canUnban: true } });
    });

    it('submits the form when button is clicked', () => {
      expect(findButton().attributes('type')).toBe('submit');
    });

    it('displays form with correct inputs', () => {
      expect(findForm().find('input[name="_method"]').attributes('value')).toBe('put');
      expect(findForm().find('input[name="authenticity_token"]').attributes('value')).toBe(
        'mock-csrf-token',
      );
    });

    it('has the corrected rendered unbanPath', () => {
      const action = findForm().attributes('action');
      expect(action).toBe(`${DEFAULT_MEMBERS_PATH}/${member.id}/unban`);
      expect(action).not.toContain(':id');
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

  it('fails validation when member prop does not have id property with a number value', () => {
    expect(() =>
      assertProps(
        BannedActionButtons,
        { ...defaultProps, member: {} },
        { provide: { namespace: 'fake ' } },
      ),
    ).toThrow('Invalid prop: custom validator check failed');
  });
});
