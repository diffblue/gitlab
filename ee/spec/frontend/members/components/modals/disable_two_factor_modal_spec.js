import { GlModal } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { mount, createWrapper } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import DisableTwoFactorModal from 'ee/members/components/modals/disable_two_factor_modal.vue';
import { MEMBER_TYPES } from '~/members/constants';
import {
  DISABLE_TWO_FACTOR_MODAL_ID,
  I18N_CANCEL,
  I18N_DISABLE,
  I18N_DISABLE_TWO_FACTOR_MODAL_TITLE,
} from 'ee/members/constants';

const csrfToken = 'mock-csrf-token';
jest.mock('~/lib/utils/csrf', () => ({ token: csrfToken }));

Vue.use(Vuex);

describe('DisableTwoFactorModal', () => {
  let wrapper;
  const disableTwoFactorPath = '/groups/the-group/-/two_factor_auth';
  const modalMessage = 'Modal message';
  const userId = 34;

  const actions = {
    hideDisableTwoFactorModal: jest.fn(),
  };

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
          namespaced: true,
          state: {
            disableTwoFactorPath,
            disableTwoFactorModalVisible: true,
            disableTwoFactorModalData: {
              message: modalMessage,
              userId,
            },
            ...state,
          },
          actions,
        },
      },
    });
  };

  const createComponent = (state) => {
    wrapper = mount(DisableTwoFactorModal, {
      store: createStore(state),
      provide: {
        namespace: MEMBER_TYPES.user,
      },
      attrs: {
        static: true,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => findModal().find('form');
  const getByText = (text, options) =>
    createWrapper(within(findModal().element).getByText(text, options));

  describe('when modal is open', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets modal ID', () => {
      expect(findModal().props('modalId')).toBe(DISABLE_TWO_FACTOR_MODAL_ID);
    });

    it('displays modal title', () => {
      expect(getByText(I18N_DISABLE_TWO_FACTOR_MODAL_TITLE).exists()).toBe(true);
    });

    it('displays modal body', () => {
      expect(getByText(modalMessage).exists()).toBe(true);
    });

    it('displays form with correct action and inputs', () => {
      const form = findForm();

      expect(form.attributes('action')).toBe(disableTwoFactorPath);
      expect(form.find('input[name="_method"]').attributes('value')).toBe('delete');
      expect(form.find('input[name="user_id"]').attributes('value')).toBe(`${userId}`);
      expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(csrfToken);
    });

    it('submits the form when primary button is clicked', () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');

      getByText(I18N_DISABLE).trigger('click');

      expect(submitSpy).toHaveBeenCalled();

      submitSpy.mockRestore();
    });

    it('calls `hideDisableTwoFactorModal` action when modal is closed', () => {
      getByText(I18N_CANCEL).trigger('click');

      expect(actions.hideDisableTwoFactorModal).toHaveBeenCalled();
    });
  });

  it('modal does not show when `disableTwoFactorModalVisible` is `false`', () => {
    createComponent({ disableTwoFactorModalVisible: false });

    expect(findModal().props().visible).toBe(false);
  });
});
