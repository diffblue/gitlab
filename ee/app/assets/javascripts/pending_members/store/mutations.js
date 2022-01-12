import { sprintf } from '~/locale';
import { HEADER_TOTAL_ENTRIES, HEADER_PAGE_NUMBER, HEADER_ITEMS_PER_PAGE } from '../constants';
import * as types from './mutation_types';

export default {
  [types.REQUEST_PENDING_MEMBERS](state) {
    state.isLoading = true;
    state.hasError = false;
  },

  [types.RECEIVE_PENDING_MEMBERS_SUCCESS](state, payload) {
    const { data, headers } = payload;
    state.members = data;

    state.total = Number(headers[HEADER_TOTAL_ENTRIES]);
    state.page = Number(headers[HEADER_PAGE_NUMBER]);
    state.perPage = Number(headers[HEADER_ITEMS_PER_PAGE]);

    state.isLoading = false;
  },

  [types.RECEIVE_PENDING_MEMBERS_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },

  [types.SET_CURRENT_PAGE](state, pageNumber) {
    state.page = pageNumber;
  },

  [types.SET_MEMBER_AS_LOADING](state, id) {
    state.members = state.members.map((member) => {
      if (member.id === id) {
        return { ...member, loading: true };
      }
      return member;
    });
  },

  [types.SET_MEMBER_AS_APPROVED](state, id) {
    state.members = state.members.map((member) => {
      if (member.id === id) {
        return { ...member, approved: true, loading: false };
      }
      return member;
    });
  },

  [types.SET_MEMBER_ERROR](state, id) {
    state.members = state.members.map((member) => {
      if (member.id === id) {
        return { ...member, loading: false };
      }
      return member;
    });
  },

  [types.DISMISS_ALERT](state) {
    state.alertMessage = '';
  },

  [types.SHOW_ALERT](state, payload) {
    const { memberId, alertMessage, alertVariant } = payload;

    if (memberId) {
      const member = state.members.find((m) => m.id === memberId);

      state.alertMessage = sprintf(alertMessage, {
        user: member.name || member.email,
      });
    } else {
      state.alertMessage = alertMessage;
    }

    state.alertVariant = alertVariant;
  },
};
