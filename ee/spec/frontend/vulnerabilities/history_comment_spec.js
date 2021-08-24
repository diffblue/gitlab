import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import deleteNoteMutation from 'ee/security_dashboard/graphql/mutations/note_delete.mutation.graphql';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import HistoryComment from 'ee/vulnerabilities/components/history_comment.vue';
import HistoryCommentEditor from 'ee/vulnerabilities/components/history_comment_editor.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

const mockAxios = new MockAdapter(axios);
jest.mock('~/flash');

Vue.use(VueApollo);

describe('History Comment', () => {
  let wrapper;

  const createApolloProvider = (...queries) => {
    return createMockApollo([...queries]);
  };

  const createWrapper = ({ comment, apolloProvider } = {}) => {
    wrapper = mount(HistoryComment, {
      apolloProvider,
      propsData: {
        comment,
        notesUrl: '/notes',
      },
    });
  };

  const comment = {
    id: 'id',
    note: 'note',
    noteHtml: '<p>note</p>',
    author: {},
    updatedAt: new Date().toISOString(),
    currentUser: {
      canEdit: true,
    },
  };

  const addCommentButton = () => wrapper.find({ ref: 'addCommentButton' });
  const commentEditor = () => wrapper.find(HistoryCommentEditor);
  const eventItem = () => wrapper.find(EventItem);
  const editButton = () => wrapper.find('[title="Edit Comment"]');
  const deleteButton = () => wrapper.find('[title="Delete Comment"]');
  const confirmDeleteButton = () => wrapper.find({ ref: 'confirmDeleteButton' });
  const cancelDeleteButton = () => wrapper.find({ ref: 'cancelDeleteButton' });

  // Check that the passed-in elements exist, and that everything else does not exist.
  const expectExists = (...expectedElements) => {
    const set = new Set(expectedElements);

    expect(addCommentButton().exists()).toBe(set.has(addCommentButton));
    expect(commentEditor().exists()).toBe(set.has(commentEditor));
    expect(eventItem().exists()).toBe(set.has(eventItem));
    expect(editButton().exists()).toBe(set.has(editButton));
    expect(deleteButton().exists()).toBe(set.has(deleteButton));
    expect(confirmDeleteButton().exists()).toBe(set.has(confirmDeleteButton));
    expect(cancelDeleteButton().exists()).toBe(set.has(cancelDeleteButton));
  };

  const expectAddCommentView = () => expectExists(addCommentButton);
  const expectExistingCommentView = () => expectExists(eventItem, editButton, deleteButton);
  const expectEditCommentView = () => expectExists(commentEditor);
  const expectDeleteConfirmView = () => {
    expectExists(eventItem, confirmDeleteButton, cancelDeleteButton);
  };

  // Either the add comment button or the edit button will exist, but not both at the same time, so we'll just find
  // whichever one exists and click it to show the editor.
  const showEditView = () => {
    if (addCommentButton().exists()) {
      addCommentButton().trigger('click');
    } else {
      editButton().vm.$emit('click');
    }

    return wrapper.vm.$nextTick();
  };

  afterEach(() => {
    wrapper.destroy();
    mockAxios.reset();
    createFlash.mockReset();
  });

  describe(`when there's no existing comment`, () => {
    beforeEach(() => createWrapper());

    it('shows the add comment button', () => {
      expectAddCommentView();
    });

    it('shows the comment editor when the add comment button is clicked', () => {
      return showEditView().then(() => {
        expectEditCommentView();
        expect(commentEditor().props('initialComment')).toBeFalsy();
      });
    });

    it('shows the add comment button when the cancel button is clicked in the comment editor', () => {
      return showEditView()
        .then(() => {
          commentEditor().vm.$emit('onCancel');
          return wrapper.vm.$nextTick();
        })
        .then(expectAddCommentView);
    });

    it('saves the comment when the save button is clicked on the comment editor', () => {
      mockAxios.onPost().replyOnce(200, comment);

      return showEditView()
        .then(() => {
          commentEditor().vm.$emit('onSave', 'new comment');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(commentEditor().props('isSaving')).toBe(true);
          return axios.waitForAll();
        })
        .then(() => {
          expect(mockAxios.history.post).toHaveLength(1);
          expect(wrapper.emitted().onCommentAdded[0]).toEqual([
            { response: comment, comment: undefined },
          ]);
        });
    });

    it('shows an error message and continues showing the comment editor when the comment cannot be saved', () => {
      mockAxios.onPost().replyOnce(500);

      return showEditView()
        .then(() => {
          commentEditor().vm.$emit('onSave', 'new comment');
          return axios.waitForAll();
        })
        .then(() => {
          expect(mockAxios.history.post).toHaveLength(1);
          expect(createFlash).toHaveBeenCalledTimes(1);
          expect(commentEditor().exists()).toBe(true);
        });
    });
  });

  describe(`when there's an existing comment`, () => {
    beforeEach(() => createWrapper({ comment }));

    it('shows the comment with the correct user author and timestamp and the edit/delete buttons', () => {
      expectExistingCommentView();
      expect(eventItem().props('author')).toBe(comment.author);
      expect(eventItem().props('createdAt')).toBe(comment.updatedAt);
      expect(eventItem().element.innerHTML).toContain(comment.noteHtml);
    });

    it('shows the comment editor when the edit button is clicked', () => {
      return showEditView().then(() => {
        expectEditCommentView();
        expect(commentEditor().props('initialComment')).toBe(comment.note);
      });
    });

    it('shows the comment when the cancel button is clicked in the comment editor', () => {
      return showEditView()
        .then(() => {
          commentEditor().vm.$emit('onCancel');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expectExistingCommentView();
          expect(eventItem().element.innerHTML).toContain(comment.noteHtml);
        });
    });

    it('shows the delete confirmation buttons when the delete button is clicked', () => {
      deleteButton().trigger('click');

      return wrapper.vm.$nextTick().then(expectDeleteConfirmView);
    });

    it('shows the comment when the cancel button is clicked on the delete confirmation', () => {
      deleteButton().trigger('click');

      return wrapper.vm
        .$nextTick()
        .then(() => {
          cancelDeleteButton().trigger('click');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expectExistingCommentView();
          expect(eventItem().element.innerHTML).toContain(comment.noteHtml);
        });
    });

    it('saves the comment when the save button is clicked on the comment editor', () => {
      const responseData = { ...comment, note: 'new comment' };
      mockAxios.onPut().replyOnce(200, responseData);

      return showEditView()
        .then(() => {
          commentEditor().vm.$emit('onSave', responseData.note);
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(commentEditor().props('isSaving')).toBe(true);
          return axios.waitForAll();
        })
        .then(() => {
          expect(mockAxios.history.put).toHaveLength(1);
          expect(wrapper.emitted().onCommentUpdated[0]).toEqual([
            { response: responseData, comment },
          ]);
        });
    });

    it('shows an error message when the comment cannot be saved', () => {
      mockAxios.onPut().replyOnce(500);

      return showEditView()
        .then(() => {
          commentEditor().vm.$emit('onSave', 'some comment');
          return axios.waitForAll();
        })
        .then(() => {
          expect(mockAxios.history.put).toHaveLength(1);
          expect(createFlash).toHaveBeenCalledTimes(1);
        });
    });
  });

  describe('deleting a note', () => {
    it('deletes the comment when the confirm delete button is clicked', async () => {
      createWrapper({
        comment,
        apolloProvider: createApolloProvider([
          deleteNoteMutation,
          jest.fn().mockResolvedValue({
            data: {
              destroyNote: {
                errors: [],
                note: null,
              },
            },
          }),
        ]),
      });

      deleteButton().trigger('click');

      await wrapper.vm.$nextTick();
      confirmDeleteButton().trigger('click');

      await wrapper.vm.$nextTick();
      expect(confirmDeleteButton().props('loading')).toBe(true);
      expect(cancelDeleteButton().props('disabled')).toBe(true);

      await axios.waitForAll();
      expect(wrapper.emitted().onCommentDeleted).toBeTruthy();
      expect(wrapper.emitted().onCommentDeleted[0][0]).toEqual(comment);
    });

    it('shows an error message when the comment cannot be deleted', async () => {
      createWrapper({
        comment,
        apolloProvider: createApolloProvider([
          deleteNoteMutation,
          jest.fn().mockRejectedValue({
            data: {
              destroyNote: {
                errors: [{ message: 'Something went wrong' }],
                note: null,
              },
            },
          }),
        ]),
      });

      deleteButton().trigger('click');

      await wrapper.vm.$nextTick();
      confirmDeleteButton().trigger('click');

      await axios.waitForAll();
      expect(createFlash).toHaveBeenCalledTimes(1);
    });
  });

  describe('no permission to edit existing comment', () => {
    it('does not show the edit/delete buttons if the current user has no edit permissions', () => {
      createWrapper({ comment: { ...comment, currentUser: { canEdit: false } } });

      expect(editButton().exists()).toBe(false);
      expect(deleteButton().exists()).toBe(false);
    });
  });
});
