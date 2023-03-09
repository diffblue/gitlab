import Vue from 'vue';
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SubmitDropdown from '~/batch_comments/components/submit_dropdown.vue';

Vue.use(Vuex);

let wrapper;
let publishReview;

function factory({ canApprove = true, requirePasswordToApprove = true } = {}) {
  publishReview = jest.fn();

  const store = new Vuex.Store({
    getters: {
      getNotesData: () => ({
        markdownDocsPath: '/markdown/docs',
        quickActionsDocsPath: '/quickactions/docs',
      }),
      getNoteableData: () => ({
        id: 1,
        preview_note_path: '/preview',
        current_user: {
          can_approve: canApprove,
        },
        require_password_to_approve: requirePasswordToApprove,
      }),
      noteableType: () => 'merge_request',
    },
    modules: {
      batchComments: {
        namespaced: true,
        actions: {
          publishReview,
        },
      },
    },
  });
  wrapper = mountExtended(SubmitDropdown, {
    store,
  });
}

describe('Batch comments submit dropdown', () => {
  it.each`
    requirePasswordToApprove | exists   | existsText
    ${true}                  | ${true}  | ${'shows'}
    ${false}                 | ${false} | ${'hides'}
  `(
    '$existsText approve password if require_password_to_approve is $requirePasswordToApprove',
    async ({ requirePasswordToApprove, exists }) => {
      factory({ requirePasswordToApprove });

      await waitForPromises();

      expect(wrapper.findByTestId('approve_password').exists()).toBe(exists);
    },
  );
});
