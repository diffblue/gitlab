import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createNoteMutation from 'ee/security_dashboard/graphql/mutations/note_create.mutation.graphql';
import destroyNoteMutation from 'ee/security_dashboard/graphql/mutations/note_destroy.mutation.graphql';
import updateNoteMutation from 'ee/security_dashboard/graphql/mutations/note_update.mutation.graphql';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import HistoryComment from 'ee/vulnerabilities/components/history_comment.vue';
import HistoryCommentEditor from 'ee/vulnerabilities/components/history_comment_editor.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { TYPENAME_DISCUSSION, TYPENAME_VULNERABILITY } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { generateNote } from './mock_data';

jest.mock('~/alert');
Vue.use(VueApollo);

const CREATE_NOTE = 'createNote';
const UPDATE_NOTE = 'updateNote';
const DESTROY_NOTE = 'destroyNote';

const TEST_VULNERABILITY_ID = '15';
const TEST_DISCUSSION_ID = '24';
const TEST_VULNERABILITY_GID = convertToGraphQLId(TYPENAME_VULNERABILITY, TEST_VULNERABILITY_ID);
const TEST_DISCUSSION_GID = convertToGraphQLId(TYPENAME_DISCUSSION, TEST_DISCUSSION_ID);

describe('History Comment', () => {
  let wrapper;
  let createNoteMutationSpy;
  let updateNoteMutationSpy;
  let destroyNoteMutationSpy;

  const createMutationResponse = ({ note = {}, queryName, errors = [] }) => ({
    data: {
      [queryName]: {
        errors,
        note,
      },
    },
  });

  const createWrapper = ({ propsData } = {}) => {
    const apolloProvider = createMockApollo([
      [createNoteMutation, createNoteMutationSpy],
      [updateNoteMutation, updateNoteMutationSpy],
      [destroyNoteMutation, destroyNoteMutationSpy],
    ]);

    wrapper = mountExtended(HistoryComment, {
      apolloProvider,
      provide: {
        vulnerabilityId: TEST_VULNERABILITY_ID,
      },
      propsData: {
        discussionId: TEST_DISCUSSION_ID,
        ...propsData,
      },
      attachTo: document.body,
    });
  };

  const note = generateNote();

  beforeEach(() => {
    createNoteMutationSpy = jest
      .fn()
      .mockResolvedValue(createMutationResponse({ queryName: CREATE_NOTE, note }));
    destroyNoteMutationSpy = jest
      .fn()
      .mockResolvedValue(createMutationResponse({ queryName: DESTROY_NOTE, note: null }));
    updateNoteMutationSpy = jest
      .fn()
      .mockResolvedValue(createMutationResponse({ queryName: UPDATE_NOTE, note }));
  });

  const addCommentTextarea = () => wrapper.findByTestId('add-comment-textarea');
  const commentEditor = () => wrapper.findComponent(HistoryCommentEditor);
  const eventItem = () => wrapper.findComponent(EventItem);
  const editButton = () => wrapper.find('[title="Edit Comment"]');
  const deleteButton = () => wrapper.find('[title="Delete Comment"]');
  const confirmDeleteButton = () => wrapper.findByTestId('confirm-delete-button');
  const cancelDeleteButton = () => wrapper.findByTestId('cancel-delete-button');

  // Check that the passed-in elements exist, and that everything else does not exist.
  const expectExists = (...expectedElements) => {
    const set = new Set(expectedElements);

    expect(addCommentTextarea().exists()).toBe(set.has(addCommentTextarea));
    expect(commentEditor().exists()).toBe(set.has(commentEditor));
    expect(eventItem().exists()).toBe(set.has(eventItem));
    expect(editButton().exists()).toBe(set.has(editButton));
    expect(deleteButton().exists()).toBe(set.has(deleteButton));
    expect(confirmDeleteButton().exists()).toBe(set.has(confirmDeleteButton));
    expect(cancelDeleteButton().exists()).toBe(set.has(cancelDeleteButton));
  };

  const expectAddCommentView = () => expectExists(addCommentTextarea);
  const expectExistingCommentView = () => expectExists(eventItem, editButton, deleteButton);
  const expectEditCommentView = () => expectExists(commentEditor);
  const expectDeleteConfirmView = () => {
    expectExists(eventItem, confirmDeleteButton, cancelDeleteButton);
  };

  // Either the add comment textarea or the edit button will exist, but not both at the same time.
  // If the add comment textarea exists we focus it, otherwise we click the edit button.
  const showEditView = () => {
    if (addCommentTextarea().exists()) {
      return addCommentTextarea().trigger('focus');
    }

    editButton().vm.$emit('click');
    return nextTick();
  };

  const editAndSaveNewContent = async (content) => {
    await showEditView();
    commentEditor().vm.$emit('onSave', content);
    return nextTick();
  };

  afterEach(() => {
    createAlert.mockReset();
  });

  describe(`when there's no existing comment`, () => {
    beforeEach(() => createWrapper());

    it('shows the add comment button', () => {
      expectAddCommentView();
    });

    it('shows the comment editor when the add comment button is focused', async () => {
      await showEditView();

      expectEditCommentView();
      expect(commentEditor().props('initialComment')).toBe('');
    });

    it('shows the add comment button when the cancel button is clicked in the comment editor', async () => {
      await showEditView();
      await commentEditor().vm.$emit('onCancel');

      expectAddCommentView();
    });
  });

  describe(`when there's an existing comment`, () => {
    beforeEach(() => createWrapper({ propsData: { comment: note, discussionId: '24' } }));

    it('shows the comment with the correct user author and timestamp and the edit/delete buttons', () => {
      expectExistingCommentView();
      expect(eventItem().props('author')).toBe(note.author);
      expect(eventItem().props('createdAt')).toBe(note.updatedAt);
      expect(eventItem().element.innerHTML).toContain(note.bodyHtml);
    });

    it('shows the comment editor when the edit button is clicked', () => {
      return showEditView().then(() => {
        expectEditCommentView();
        expect(commentEditor().props('initialComment')).toBe(note.body);
      });
    });

    it('shows the comment when the cancel button is clicked in the comment editor', async () => {
      await showEditView();
      await commentEditor().vm.$emit('onCancel');

      expectExistingCommentView();
      expect(eventItem().element.innerHTML).toContain(note.bodyHtml);
    });

    it('shows the delete confirmation buttons when the delete button is clicked', async () => {
      await deleteButton().trigger('click');

      expectDeleteConfirmView();
    });

    it('shows the comment when the cancel button is clicked on the delete confirmation', async () => {
      await deleteButton().trigger('click');
      await cancelDeleteButton().trigger('click');

      expectExistingCommentView();
      expect(eventItem().element.innerHTML).toContain(note.bodyHtml);
    });
  });

  const EXPECTED_CREATE_VARS = {
    discussionId: TEST_DISCUSSION_GID,
    noteableId: TEST_VULNERABILITY_GID,
  };
  const EXPECTED_UPDATE_VARS = {
    id: note.id,
  };

  describe.each`
    desc                           | propsData            | expectedVars            | mutationSpyFn                  | queryName
    ${'inserting a new note'}      | ${{}}                | ${EXPECTED_CREATE_VARS} | ${() => createNoteMutationSpy} | ${CREATE_NOTE}
    ${'updating an existing note'} | ${{ comment: note }} | ${EXPECTED_UPDATE_VARS} | ${() => updateNoteMutationSpy} | ${UPDATE_NOTE}
  `('$desc', ({ propsData, expectedVars, mutationSpyFn, queryName }) => {
    let mutationSpy;

    beforeEach(() => {
      mutationSpy = mutationSpyFn();
    });

    it('sends graphql mutation', async () => {
      createWrapper({ propsData });

      await editAndSaveNewContent('new comment');

      expect(mutationSpy).toHaveBeenCalledWith({
        ...expectedVars,
        body: 'new comment',
      });
    });

    it('shows loading', async () => {
      createWrapper({ propsData });

      await editAndSaveNewContent('new comment');

      expect(commentEditor().props('isSaving')).toBe(true);
    });

    it('emits event when mutation is successful with a callback function that resets the state', async () => {
      createWrapper({ propsData });

      const listener = jest.fn().mockImplementation((callback) => callback());
      wrapper.vm.$on('onCommentUpdated', listener);

      await editAndSaveNewContent('new comment');
      expect(commentEditor().props('isSaving')).toBe(true);
      await waitForPromises();

      expect(wrapper.emitted('onCommentUpdated')).toEqual([[expect.any(Function)]]);
      expect(listener).toHaveBeenCalled();
      expect(commentEditor().exists()).toBe(false);
    });

    describe('when mutation has data error', () => {
      beforeEach(() => {
        mutationSpy.mockResolvedValue({ queryName, errors: ['Some domain specific error'] });
        createWrapper({ propsData });
      });

      it('shows alert', async () => {
        await editAndSaveNewContent('new comment');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong while trying to save the comment. Please try again later.',
        });
      });
    });

    describe('when mutation has top-level error', () => {
      beforeEach(() => {
        mutationSpy.mockRejectedValue(new Error('Something top-level happened'));

        createWrapper({ propsData });
      });

      it('shows alert', async () => {
        await editAndSaveNewContent('new comment');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong while trying to save the comment. Please try again later.',
        });

        expect(commentEditor().exists()).toBe(true);
      });
    });
  });

  describe('deleting a note', () => {
    it('deletes the comment when the confirm delete button is clicked and submits an event to refect the discussions', async () => {
      createWrapper({
        propsData: { comment: note },
      });

      await deleteButton().trigger('click');

      await confirmDeleteButton().trigger('click');

      expect(confirmDeleteButton().props('loading')).toBe(true);
      expect(cancelDeleteButton().props('disabled')).toBe(true);

      await waitForPromises();
      expect(wrapper.emitted().onCommentUpdated).toEqual([[expect.any(Function)]]);
    });

    it('sends mutation to delete note', async () => {
      createWrapper({ propsData: { comment: note } });

      await deleteButton().trigger('click');

      confirmDeleteButton().trigger('click');
      expect(destroyNoteMutationSpy).toHaveBeenCalledWith({
        id: note.id,
      });
    });

    it('with data error, shows an error message', async () => {
      destroyNoteMutationSpy.mockResolvedValue({ errors: ['Some domain specific error'] });
      createWrapper({ propsData: { comment: note } });

      await deleteButton().trigger('click');

      confirmDeleteButton().trigger('click');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while trying to delete the comment. Please try again later.',
      });
    });

    it('with top-level error, shows an error message', async () => {
      destroyNoteMutationSpy.mockRejectedValue(new Error('Some top-level error'));
      createWrapper({ propsData: { comment: note } });

      await deleteButton().trigger('click');

      confirmDeleteButton().trigger('click');

      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while trying to delete the comment. Please try again later.',
      });
    });
  });

  describe('no permission to edit existing comment', () => {
    it('does not show the edit/delete buttons if the current user has no edit permissions', () => {
      createWrapper({
        propsData: {
          comment: { ...note, userPermissions: { adminNote: false } },
        },
      });

      expect(editButton().exists()).toBe(false);
      expect(deleteButton().exists()).toBe(false);
    });
  });
});
