import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { noop } from 'lodash';
import {
  showDisableTwoFactorModal,
  hideDisableTwoFactorModal,
  updateLdapOverride,
  showLdapOverrideConfirmationModal,
  hideLdapOverrideConfirmationModal,
} from 'ee/members/store/actions';
import * as types from 'ee/members/store/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import { members, member } from 'jest/members/mock_data';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('Vuex members actions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('disable two factor confirmation modal', () => {
    const state = {
      disableTwoFactorModalData: null,
      disableTwoFactorModalVisible: false,
    };

    describe('showDisableTwoFactorModal', () => {
      it(`commits ${types.SHOW_DISABLE_TWO_FACTOR_MODAL} mutation`, () => {
        const modalData = { userID: 5, name: 'John Malone' };
        testAction(showDisableTwoFactorModal, modalData, state, [
          {
            type: types.SHOW_DISABLE_TWO_FACTOR_MODAL,
            payload: modalData,
          },
        ]);
      });
    });

    describe('hideDisableTwoFactorModal', () => {
      it(`commits ${types.HIDE_DISABLE_TWO_FACTOR_MODAL} mutation`, () => {
        testAction(hideDisableTwoFactorModal, {}, state, [
          {
            type: types.HIDE_DISABLE_TWO_FACTOR_MODAL,
          },
        ]);
      });
    });
  });

  describe('updateLdapOverride', () => {
    const payload = {
      memberId: members[0].id,
      override: true,
    };

    const state = {
      members,
      ldapOverridePath: '/groups/ldap-group/-/group_members/:id/override',
      requestFormatter: noop,
    };

    describe('successful request', () => {
      it(`commits ${types.RECEIVE_LDAP_OVERRIDE_SUCCESS} mutation`, async () => {
        mock.onPatch().replyOnce(HTTP_STATUS_OK);

        await testAction(updateLdapOverride, payload, state, [
          {
            type: types.RECEIVE_LDAP_OVERRIDE_SUCCESS,
            payload,
          },
        ]);

        expect(mock.history.patch[0].url).toBe('/groups/ldap-group/-/group_members/238/override');
      });
    });

    describe('unsuccessful request', () => {
      beforeEach(() => {
        mock.onPatch().networkError();
      });

      it(`commits ${types.RECEIVE_LDAP_OVERRIDE_ERROR} mutation and throws error`, async () => {
        await expect(
          testAction(updateLdapOverride, {}, state, [
            {
              type: types.RECEIVE_LDAP_OVERRIDE_ERROR,
            },
          ]),
        ).rejects.toThrow(new Error('Network Error'));
      });
    });
  });

  describe('LDAP override confirmation modal', () => {
    const state = {
      memberToOverride: null,
      ldapOverrideConfirmationModalVisible: false,
    };

    describe('showLdapOverrideConfirmationModal', () => {
      it(`commits ${types.SHOW_LDAP_OVERRIDE_CONFIRMATION_MODAL} mutation`, () => {
        testAction(showLdapOverrideConfirmationModal, member, state, [
          {
            type: types.SHOW_LDAP_OVERRIDE_CONFIRMATION_MODAL,
            payload: member,
          },
        ]);
      });
    });

    describe('hideLdapOverrideConfirmationModal', () => {
      it(`commits ${types.HIDE_LDAP_OVERRIDE_CONFIRMATION_MODAL} mutation`, () => {
        testAction(hideLdapOverrideConfirmationModal, {}, state, [
          {
            type: types.HIDE_LDAP_OVERRIDE_CONFIRMATION_MODAL,
          },
        ]);
      });
    });
  });
});
