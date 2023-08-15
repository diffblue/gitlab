import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { getDiffFileMock } from 'jest/diffs/mock_data/diff_file';
import note from 'jest/notes/mock_data';
import DiffLineNoteForm from '~/diffs/components/diff_line_note_form.vue';
import NoteForm from '~/notes/components/note_form.vue';
import { SOMETHING_WENT_WRONG, SAVING_THE_COMMENT_FAILED } from '~/diffs/i18n';

Vue.use(Vuex);
jest.mock('~/alert');

describe('EE DiffLineNoteForm', () => {
  let wrapper;

  const saveDraft = jest.fn();

  const createStoreOptions = (headSha) => {
    const state = {
      notes: {
        notesData: { draftsPath: null },
        noteableData: {},
      },
    };
    const getters = {
      getUserData: jest.fn(),
      isLoggedIn: jest.fn(),
      noteableType: jest.fn(),
      resetAutoSave: jest.fn(),
    };

    return {
      state,
      getters,
      modules: {
        diffs: {
          namespaced: true,
          state: { commit: headSha || null },
          getters: {
            getDiffFileByHash: jest.fn().mockReturnValue(() => ({
              diff_refs: {
                head_sha: headSha || null,
              },
              highlighted_diff_lines: [],
            })),
          },
          actions: {
            cancelCommentForm: jest.fn(),
          },
        },
        batchComments: {
          namespaced: true,
          actions: { saveDraft },
        },
      },
    };
  };

  const createComponent = (HEAD_SHA, props = {}) => {
    const storeOptions = createStoreOptions(HEAD_SHA);
    const store = new Vuex.Store(storeOptions);

    const diffFile = getDiffFileMock();
    const diffLines = diffFile.highlighted_diff_lines;

    wrapper = shallowMount(DiffLineNoteForm, {
      propsData: {
        diffFileHash: diffFile.file_hash,
        diffLines,
        line: diffLines[0],
        noteTargetLine: diffLines[0],
        ...props,
      },
      store,
      mocks: {
        resetAutoSave: jest.fn(),
      },
    });
  };

  const submitNoteAddToReview = () =>
    wrapper.findComponent(NoteForm).vm.$emit('handleFormUpdateAddToReview', note);
  const saveDraftCommitId = () => saveDraft.mock.calls[0][1].data.note.commit_id;

  describe('when user submits note to review', () => {
    it('should call saveDraft action with commit_id === null when store has no commit', () => {
      createComponent();

      submitNoteAddToReview();

      expect(saveDraft).toHaveBeenCalledTimes(1);
      expect(saveDraftCommitId()).toBe(null);
    });

    it('should call saveDraft action with commit_id when store has commit', () => {
      const HEAD_SHA = 'abc123';
      createComponent(HEAD_SHA);

      submitNoteAddToReview();

      expect(saveDraft).toHaveBeenCalledTimes(1);
      expect(saveDraftCommitId()).toBe(HEAD_SHA);
    });

    describe('when note-form emits `handleFormUpdateAddToReview`', () => {
      const parentElement = null;
      const errorCallback = jest.fn();

      describe.each`
        scenario                  | serverError                      | message
        ${'with server error'}    | ${{ data: { errors: 'error' } }} | ${SAVING_THE_COMMENT_FAILED}
        ${'without server error'} | ${null}                          | ${SOMETHING_WENT_WRONG}
      `('$scenario', ({ serverError, message }) => {
        beforeEach(async () => {
          saveDraft.mockRejectedValue(serverError);

          createComponent();

          wrapper
            .findComponent(NoteForm)
            .vm.$emit(
              'handleFormUpdateAddToReview',
              'invalid note',
              false,
              parentElement,
              errorCallback,
            );

          await waitForPromises();
        });

        it(`renders ${serverError ? 'server' : 'generic'} error message`, () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: sprintf(message, { reason: serverError?.data?.errors }),
            parent: parentElement,
          });
        });

        it('calls errorCallback', () => {
          expect(errorCallback).toHaveBeenCalled();
        });
      });
    });
  });
});
