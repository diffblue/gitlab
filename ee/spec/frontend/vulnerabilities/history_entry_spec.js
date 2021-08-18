import { shallowMount } from '@vue/test-utils';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import HistoryEntry from 'ee/vulnerabilities/components/history_entry.vue';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';

describe('History Entry', () => {
  let wrapper;

  const systemNote = {
    system: true,
    id: 1,
    note: 'changed vulnerability status to dismissed',
    systemNoteIconName: 'cancel',
    updatedAt: new Date().toISOString(),
    author: {
      name: 'author name',
      username: 'author username',
      status_tooltip_html: '<span class="status">status_tooltip_html</span>',
    },
  };

  const commentNote = {
    id: 2,
    note: 'some note',
    author: {},
    currentUser: {
      canEdit: true,
    },
  };

  const createWrapper = (...notes) => {
    const discussion = { notes };

    wrapper = shallowMount(HistoryEntry, {
      propsData: {
        discussion,
        notesUrl: '/notes',
      },
      stubs: { EventItem },
    });
  };

  const eventItem = () => wrapper.findComponent(EventItem);
  const newComment = () => wrapper.findComponent({ ref: 'newComment' });
  const existingComments = () => wrapper.findAllComponents({ ref: 'existingComment' });
  const commentAt = (index) => existingComments().at(index);

  afterEach(() => wrapper.destroy());

  it('passes the expected values to the event item component', () => {
    createWrapper(systemNote);

    expect(eventItem().text()).toContain(systemNote.note);
    expect(eventItem().props()).toMatchObject({
      id: systemNote.id,
      author: systemNote.author,
      createdAt: systemNote.updatedAt,
      iconName: systemNote.systemNoteIconName,
    });
  });

  it('does not show anything if there is no system note', () => {
    createWrapper();

    expect(wrapper.html()).toBeFalsy();
  });

  it('shows the add comment button where there are no comments', () => {
    createWrapper(systemNote);

    expect(newComment().exists()).toBe(true);
    expect(existingComments()).toHaveLength(0);
  });

  it('displays comments when there are comments', () => {
    const commentNoteClone = { ...commentNote, id: 3, note: 'different note' };
    createWrapper(systemNote, commentNote, commentNoteClone);

    expect(newComment().exists()).toBe(false);
    expect(existingComments()).toHaveLength(2);
    expect(commentAt(0).props('comment')).toEqual(commentNote);
    expect(commentAt(1).props('comment')).toEqual(commentNoteClone);
  });

  it('adds a new comment correctly', async () => {
    createWrapper(systemNote);
    newComment().vm.$emit('onCommentAdded', {
      response: convertObjectPropsToSnakeCase(commentNote),
    });

    await wrapper.vm.$nextTick();

    expect(newComment().exists()).toBe(false);
    expect(existingComments()).toHaveLength(1);
    expect(commentAt(0).props('comment')).toEqual(commentNote);
  });

  it('updates an existing comment correctly', async () => {
    const response = { note: 'new note' };
    createWrapper(systemNote, commentNote);
    commentAt(0).vm.$emit('onCommentUpdated', { response, comment: commentNote });

    await wrapper.vm.$nextTick();

    expect(commentAt(0).props('comment')).toEqual({ ...commentNote, note: response.note });
  });

  it('deletes an existing comment correctly', async () => {
    createWrapper(systemNote, commentNote);
    await commentAt(0).vm.$emit('onCommentDeleted', commentNote);

    expect(newComment().exists()).toBe(true);
    expect(existingComments()).toHaveLength(0);
  });
});
