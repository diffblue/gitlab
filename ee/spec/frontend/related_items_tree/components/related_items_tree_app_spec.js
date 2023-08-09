import { GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import Api from 'ee/api';
import mockProjects from 'test_fixtures_static/projects.json';
import CreateIssueForm from 'ee/related_items_tree/components/create_issue_form.vue';
import CreateEpicForm from 'ee/related_items_tree/components/create_epic_form.vue';
import AddItemForm from '~/related_issues/components/add_issuable_form.vue';
import SlotSwitch from '~/vue_shared/components/slot_switch.vue';
import RelatedItemsTreeApp from 'ee/related_items_tree/components/related_items_tree_app.vue';
import RelatedItemsTreeHeader from 'ee/related_items_tree/components/related_items_tree_header.vue';
import RelatedItemsTreeActions from 'ee/related_items_tree/components/related_items_tree_actions.vue';
import RelatedItemsTreeBody from 'ee/related_items_tree/components/related_items_tree_body.vue';
import RelatedItemsRoadmapApp from 'ee/related_items_tree/components/related_items_roadmap_app.vue';

import createDefaultStore from 'ee/related_items_tree/store';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { ITEM_TABS } from 'ee/related_items_tree/constants';

import { mockInitialConfig, mockParentItem, mockEpics, mockIssues } from '../mock_data';

Vue.use(Vuex);

describe('RelatedItemsTreeApp', () => {
  let axiosMock;
  let wrapper;
  let store;

  const createComponent = () => {
    store = createDefaultStore();

    store.dispatch('setInitialConfig', mockInitialConfig);
    store.dispatch('setInitialParentItem', mockParentItem);
    store.dispatch('setItemChildren', {
      parentItem: mockParentItem,
      children: [...mockEpics, ...mockIssues],
    });

    jest.spyOn(store, 'dispatch');

    wrapper = shallowMountExtended(RelatedItemsTreeApp, {
      store,
      stubs: {
        SlotSwitch,
      },
    });
  };

  const findCreateIssueForm = () => wrapper.findComponent(CreateIssueForm);
  const findAddItemForm = () => wrapper.findComponent(AddItemForm);
  const findCreateEpicForm = () => wrapper.findComponent(CreateEpicForm);
  const findRelatedItemsTreeActions = () => wrapper.findComponent(RelatedItemsTreeActions);
  const findRelatedItemsTreeHeader = () => wrapper.findComponent(RelatedItemsTreeHeader);

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(mockInitialConfig.projectsEndpoint).replyOnce(HTTP_STATUS_OK, mockProjects);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('methods', () => {
    beforeEach(() => {
      createComponent();
      store.state.showAddItemForm = true;
    });

    describe('getRawRefs', () => {
      it('returns array of references from provided string with spaces', () => {
        const value = '&1 &2 &3';
        const references = wrapper.vm.getRawRefs(value);

        expect(references).toHaveLength(3);
        expect(references.join(' ')).toBe(value);
      });
    });

    describe('handlePendingItemRemove', () => {
      it('calls `removePendingReference` action with provided `index` param', () => {
        findAddItemForm().vm.$emit('pendingIssuableRemoveRequest', 0);

        expect(store.dispatch).toHaveBeenCalledWith('removePendingReference', 0);
      });
    });

    describe('handleAddItemFormInput', () => {
      const untouchedRawReferences = ['&1'];
      const touchedReference = '&2';

      it('calls `addPendingReferences` action with provided `untouchedRawReferences` param', () => {
        findAddItemForm().vm.$emit('addIssuableFormInput', {
          untouchedRawReferences,
          touchedReference,
        });

        expect(store.dispatch).toHaveBeenCalledWith('addPendingReferences', untouchedRawReferences);
      });

      it('calls `setItemInputValue` action with provided `touchedReference` param', () => {
        findAddItemForm().vm.$emit('addIssuableFormInput', {
          untouchedRawReferences,
          touchedReference,
        });

        expect(store.dispatch).toHaveBeenCalledWith('setItemInputValue', touchedReference);
      });
    });

    describe('handleAddItemFormBlur', () => {
      const newValue = '&1 &2';

      it('calls `addPendingReferences` action with provided `newValue` param', () => {
        findAddItemForm().vm.$emit('addIssuableFormBlur', newValue);

        expect(store.dispatch).toHaveBeenCalledWith('addPendingReferences', newValue.split(/\s+/));
      });

      it('calls `setItemInputValue` action with empty string', () => {
        findAddItemForm().vm.$emit('addIssuableFormBlur', newValue);

        expect(store.dispatch).toHaveBeenCalledWith('setItemInputValue', '');
      });
    });

    describe('handleAddItemFormSubmit', () => {
      it('calls `addItem` action when `pendingReferences` prop in state is not empty', () => {
        const emitObj = {
          pendingReferences: '&1 &2',
        };

        findAddItemForm().vm.$emit('addIssuableFormSubmit', emitObj);

        expect(store.dispatch).toHaveBeenCalledWith('addItem');
      });
    });

    describe('handleCreateEpicFormSubmit', () => {
      it('calls `createItem` action with `itemTitle` param', async () => {
        const newValue = 'foo';
        jest.spyOn(Api, 'createChildEpic').mockResolvedValue({ data: { url: '' } });
        store.dispatch('toggleAddItemForm', { toggleState: false });
        store.dispatch('toggleCreateEpicForm', { toggleState: true });
        await nextTick();

        findCreateEpicForm().vm.$emit('createEpicFormSubmit', { value: newValue });

        expect(store.dispatch).toHaveBeenCalledWith('createItem', {
          itemTitle: newValue,
          groupFullPath: undefined,
        });
      });
    });

    describe('handleAddItemFormCancel', () => {
      it('calls `toggleAddItemForm` actions with params `toggleState` as `false`', () => {
        findAddItemForm().vm.$emit('addIssuableFormCancel');

        expect(store.dispatch).toHaveBeenCalledWith('toggleAddItemForm', { toggleState: false });
      });

      it('calls `setPendingReferences` action with empty array', () => {
        findAddItemForm().vm.$emit('addIssuableFormCancel');

        expect(store.dispatch).toHaveBeenCalledWith('setPendingReferences', []);
      });

      it('calls `setItemInputValue` action with empty string', async () => {
        store.dispatch('toggleAddItemForm', { toggleState: false });
        store.dispatch('toggleCreateEpicForm', { toggleState: true });
        await nextTick();

        findCreateEpicForm().vm.$emit('createEpicFormCancel');

        expect(store.dispatch).toHaveBeenCalledWith('setItemInputValue', '');
      });
    });

    describe('handleCreateEpicFormCancel', () => {
      it('calls `toggleCreateEpicForm` actions with params `toggleState`', async () => {
        store.dispatch('toggleAddItemForm', { toggleState: false });
        store.dispatch('toggleCreateEpicForm', { toggleState: true });
        await nextTick();

        findCreateEpicForm().vm.$emit('createEpicFormCancel');

        expect(store.dispatch).toHaveBeenCalledWith('toggleCreateEpicForm', { toggleState: false });
        expect(store.dispatch).toHaveBeenCalledWith('setItemInputValue', '');
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
      store.dispatch('receiveItemsSuccess', {
        parentItem: mockParentItem,
        children: [],
        isSubItem: false,
      });
    });

    it('renders loading icon when `state.itemsFetchInProgress` prop is true', async () => {
      store.dispatch('requestItems', {
        parentItem: mockParentItem,
        isSubItem: false,
      });

      await nextTick();
      expect(wrapper.findComponent(GlLoadingIcon).isVisible()).toBe(true);
    });

    it('renders tree container element when `state.itemsFetchInProgress` prop is false', async () => {
      await nextTick();
      expect(wrapper.find('.related-items-tree').isVisible()).toBe(true);
    });

    it('renders tree container element with `disabled-content` class when `state.itemsFetchInProgress` prop is false and `state.itemAddInProgress` or `state.itemCreateInProgress` is true', async () => {
      store.dispatch('requestAddItem');

      await nextTick();
      expect(wrapper.find('.related-items-tree.disabled-content').isVisible()).toBe(true);
    });

    it('renders tree header component', async () => {
      await nextTick();
      expect(findRelatedItemsTreeHeader().isVisible()).toBe(true);
    });

    it('renders item add/create form container element', async () => {
      store.dispatch('toggleAddItemForm', {
        toggleState: true,
        issuableType: TYPE_EPIC,
      });

      await nextTick();
      expect(wrapper.findByTestId('add-item-form').isVisible()).toBe(true);
    });

    it('does not render create issue form', () => {
      expect(findCreateIssueForm().exists()).toBe(false);
    });

    it.each`
      issuableType  | autoCompleteIssues | autoCompleteEpics | expectedAutoCompleteIssues | expectedAutoCompleteEpics
      ${TYPE_ISSUE} | ${true}            | ${true}           | ${true}                    | ${false}
      ${TYPE_EPIC}  | ${true}            | ${true}           | ${false}                   | ${true}
    `(
      'enables $issuableType autocomplete only when "issuableType" is "$issuableType" and autocomplete for it is supported',
      async ({
        issuableType,
        autoCompleteIssues,
        autoCompleteEpics,
        expectedAutoCompleteIssues,
        expectedAutoCompleteEpics,
      }) => {
        store.dispatch('toggleAddItemForm', {
          toggleState: true,
          issuableType,
        });
        store.state.autoCompleteIssues = autoCompleteIssues;
        store.state.autoCompleteEpics = autoCompleteEpics;

        await nextTick();

        expect(findAddItemForm().props()).toMatchObject({
          autoCompleteIssues: expectedAutoCompleteIssues,
          autoCompleteEpics: expectedAutoCompleteEpics,
        });
      },
    );

    it('switches tab to Roadmap', async () => {
      store.state.itemsFetchResultEmpty = false;

      await nextTick();

      findRelatedItemsTreeActions().vm.$emit('tab-change', ITEM_TABS.ROADMAP);

      await nextTick();

      expect(findRelatedItemsTreeActions().props('activeTab')).toBe(ITEM_TABS.ROADMAP);
    });

    it.each`
      visibleApp        | activeTab
      ${'Tree View'}    | ${ITEM_TABS.TREE}
      ${'Roadmap View'} | ${ITEM_TABS.ROADMAP}
    `('renders $visibleApp when activeTab is $activeTab', async ({ activeTab }) => {
      store.state.itemsFetchResultEmpty = false;

      await nextTick();

      findRelatedItemsTreeActions().vm.$emit('tab-change', activeTab);

      await nextTick();

      const appMapping = {
        [ITEM_TABS.TREE]: RelatedItemsTreeBody,
        [ITEM_TABS.ROADMAP]: RelatedItemsRoadmapApp,
      };

      expect(wrapper.findComponent(appMapping[activeTab]).isVisible()).toBe(true);
    });

    it.each([false, true])(
      "toggle related items container when `toggleRelatedItemsView` emits '%s'",
      async (toggled) => {
        store.state.itemsFetchResultEmpty = false;

        await nextTick();

        findRelatedItemsTreeHeader().vm.$emit('toggleRelatedItemsView', toggled);

        await nextTick();

        expect(wrapper.findByTestId('related-items-container').exists()).toBe(toggled);
      },
    );
  });
});
