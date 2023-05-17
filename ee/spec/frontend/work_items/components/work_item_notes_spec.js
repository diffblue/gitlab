import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import SystemNote from '~/work_items/components/notes/system_note.vue';
import WorkItemNotes from '~/work_items/components/work_item_notes.vue';
import workItemNotesByIidQuery from '~/work_items/graphql/notes/work_item_notes_by_iid.query.graphql';
import deleteWorkItemNoteMutation from '~/work_items/graphql/notes/delete_work_item_notes.mutation.graphql';
import workItemNoteCreatedSubscription from '~/work_items/graphql/notes/work_item_note_created.subscription.graphql';
import workItemNoteUpdatedSubscription from '~/work_items/graphql/notes/work_item_note_updated.subscription.graphql';
import workItemNoteDeletedSubscription from '~/work_items/graphql/notes/work_item_note_deleted.subscription.graphql';
import { WIDGET_TYPE_NOTES } from '~/work_items/constants';
import {
  workItemQueryResponse,
  mockWorkItemNotesByIidResponse,
  workItemNotesCreateSubscriptionResponse,
  workItemNotesUpdateSubscriptionResponse,
  workItemNotesDeleteSubscriptionResponse,
  workItemNotesWithSystemNotesWithChangedDescription,
} from 'jest/work_items/mock_data';

const mockWorkItemId = workItemQueryResponse.data.workItem.id;
const mockWorkItemIid = workItemQueryResponse.data.workItem.iid;

describe('WorkItemNotes component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const showModal = jest.fn();

  const findAllSystemNotes = () => wrapper.findAllComponents(SystemNote);

  const workItemNotesQueryHandler = jest.fn().mockResolvedValue(mockWorkItemNotesByIidResponse);

  const workItemNotesWithChangedDescriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemNotesWithSystemNotesWithChangedDescription);
  const deleteWorkItemNoteMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: { destroyNote: { note: null, __typename: 'DestroyNote' } },
  });
  const notesCreateSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemNotesCreateSubscriptionResponse);
  const notesUpdateSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemNotesUpdateSubscriptionResponse);
  const notesDeleteSubscriptionHandler = jest
    .fn()
    .mockResolvedValue(workItemNotesDeleteSubscriptionResponse);

  const createComponent = ({
    workItemId = mockWorkItemId,
    workItemIid = mockWorkItemIid,
    defaultWorkItemNotesQueryHandler = workItemNotesQueryHandler,
    deleteWINoteMutationHandler = deleteWorkItemNoteMutationSuccessHandler,
    isModal = false,
  } = {}) => {
    wrapper = shallowMount(WorkItemNotes, {
      apolloProvider: createMockApollo([
        [workItemNotesByIidQuery, defaultWorkItemNotesQueryHandler],
        [deleteWorkItemNoteMutation, deleteWINoteMutationHandler],
        [workItemNoteCreatedSubscription, notesCreateSubscriptionHandler],
        [workItemNoteUpdatedSubscription, notesUpdateSubscriptionHandler],
        [workItemNoteDeletedSubscription, notesDeleteSubscriptionHandler],
      ]),
      provide: {
        fullPath: 'test-path',
      },
      propsData: {
        workItemId,
        workItemIid,
        workItemType: 'task',
        reportAbusePath: '/report/abuse/path',
        isModal,
      },
      stubs: {
        GlModal: stubComponent(GlModal, { methods: { show: showModal } }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('collapse system notes with description changes', () => {
    beforeEach(() => {
      createComponent({
        defaultWorkItemNotesQueryHandler: workItemNotesWithChangedDescriptionHandler,
      });
      return waitForPromises();
    });

    it('with time difference of 10 mins into one', () => {
      const notesWidget = workItemNotesWithSystemNotesWithChangedDescription.data.workspace.workItems.nodes[0].widgets.find(
        (widget) => widget.type === WIDGET_TYPE_NOTES,
      );

      const {
        discussions: { nodes },
      } = notesWidget;

      expect(findAllSystemNotes()).not.toHaveLength(nodes.length);
      expect(findAllSystemNotes()).toHaveLength(1);
    });
  });
});
