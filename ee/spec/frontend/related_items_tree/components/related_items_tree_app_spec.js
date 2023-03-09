import { GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import mockProjects from 'test_fixtures_static/projects.json';
import CreateIssueForm from 'ee/related_items_tree/components/create_issue_form.vue';
import AddIssuableForm from '~/related_issues/components/add_issuable_form.vue';
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

const createComponent = () => {
  const store = createDefaultStore();

  store.dispatch('setInitialConfig', mockInitialConfig);
  store.dispatch('setInitialParentItem', mockParentItem);
  store.dispatch('setItemChildren', {
    parentItem: mockParentItem,
    children: [...mockEpics, ...mockIssues],
  });

  return shallowMountExtended(RelatedItemsTreeApp, {
    store,
    stubs: {
      SlotSwitch,
    },
  });
};

describe('RelatedItemsTreeApp', () => {
  let axiosMock;
  let wrapper;

  const findCreateIssueForm = () => wrapper.findComponent(CreateIssueForm);
  const findAddItemForm = () => wrapper.findComponent(AddIssuableForm);

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(mockInitialConfig.projectsEndpoint).replyOnce(HTTP_STATUS_OK, mockProjects);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('methods', () => {
    beforeEach(() => {
      wrapper = createComponent();
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
        jest.spyOn(wrapper.vm, 'removePendingReference').mockImplementation();

        wrapper.vm.handlePendingItemRemove(0);

        expect(wrapper.vm.removePendingReference).toHaveBeenCalledWith(0);
      });
    });

    describe('handleAddItemFormInput', () => {
      const untouchedRawReferences = ['&1'];
      const touchedReference = '&2';

      it('calls `addPendingReferences` action with provided `untouchedRawReferences` param', () => {
        jest.spyOn(wrapper.vm, 'addPendingReferences').mockImplementation();

        wrapper.vm.handleAddItemFormInput({ untouchedRawReferences, touchedReference });

        expect(wrapper.vm.addPendingReferences).toHaveBeenCalledWith(untouchedRawReferences);
      });

      it('calls `setItemInputValue` action with provided `touchedReference` param', () => {
        jest.spyOn(wrapper.vm, 'setItemInputValue').mockImplementation();

        wrapper.vm.handleAddItemFormInput({ untouchedRawReferences, touchedReference });

        expect(wrapper.vm.setItemInputValue).toHaveBeenCalledWith(touchedReference);
      });
    });

    describe('handleAddItemFormBlur', () => {
      const newValue = '&1 &2';

      it('calls `addPendingReferences` action with provided `newValue` param', () => {
        jest.spyOn(wrapper.vm, 'addPendingReferences').mockImplementation();

        wrapper.vm.handleAddItemFormBlur(newValue);

        expect(wrapper.vm.addPendingReferences).toHaveBeenCalledWith(newValue.split(/\s+/));
      });

      it('calls `setItemInputValue` action with empty string', () => {
        jest.spyOn(wrapper.vm, 'setItemInputValue').mockImplementation();

        wrapper.vm.handleAddItemFormBlur(newValue);

        expect(wrapper.vm.setItemInputValue).toHaveBeenCalledWith('');
      });
    });

    describe('handleAddItemFormSubmit', () => {
      it('calls `addItem` action when `pendingReferences` prop in state is not empty', () => {
        const emitObj = {
          pendingReferences: '&1 &2',
        };
        jest.spyOn(wrapper.vm, 'addItem').mockImplementation();

        wrapper.vm.handleAddItemFormSubmit(emitObj);

        expect(wrapper.vm.addItem).toHaveBeenCalled();
      });
    });

    describe('handleCreateEpicFormSubmit', () => {
      it('calls `createItem` action with `itemTitle` param', () => {
        const newValue = 'foo';
        jest.spyOn(wrapper.vm, 'createItem').mockImplementation();

        wrapper.vm.handleCreateEpicFormSubmit({ value: newValue });

        expect(wrapper.vm.createItem).toHaveBeenCalledWith({
          itemTitle: newValue,
          groupFullPath: undefined,
        });
      });
    });

    describe('handleAddItemFormCancel', () => {
      it('calls `toggleAddItemForm` actions with params `toggleState` as `false`', () => {
        jest.spyOn(wrapper.vm, 'toggleAddItemForm').mockImplementation();

        wrapper.vm.handleAddItemFormCancel();

        expect(wrapper.vm.toggleAddItemForm).toHaveBeenCalledWith({ toggleState: false });
      });

      it('calls `setPendingReferences` action with empty array', () => {
        jest.spyOn(wrapper.vm, 'setPendingReferences').mockImplementation();

        wrapper.vm.handleAddItemFormCancel();

        expect(wrapper.vm.setPendingReferences).toHaveBeenCalledWith([]);
      });

      it('calls `setItemInputValue` action with empty string', () => {
        jest.spyOn(wrapper.vm, 'setItemInputValue').mockImplementation();

        wrapper.vm.handleAddItemFormCancel();

        expect(wrapper.vm.setItemInputValue).toHaveBeenCalledWith('');
      });
    });

    describe('handleCreateEpicFormCancel', () => {
      it('calls `toggleCreateEpicForm` actions with params `toggleState`', () => {
        jest.spyOn(wrapper.vm, 'toggleCreateEpicForm').mockImplementation();

        wrapper.vm.handleCreateEpicFormCancel();

        expect(wrapper.vm.toggleCreateEpicForm).toHaveBeenCalledWith({ toggleState: false });
      });

      it('calls `setItemInputValue` action with empty string', () => {
        jest.spyOn(wrapper.vm, 'setItemInputValue').mockImplementation();

        wrapper.vm.handleCreateEpicFormCancel();

        expect(wrapper.vm.setItemInputValue).toHaveBeenCalledWith('');
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      wrapper = createComponent();
      wrapper.vm.$store.dispatch('receiveItemsSuccess', {
        parentItem: mockParentItem,
        children: [],
        isSubItem: false,
      });
    });

    it('renders loading icon when `state.itemsFetchInProgress` prop is true', async () => {
      wrapper.vm.$store.dispatch('requestItems', {
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
      wrapper.vm.$store.dispatch('requestAddItem');

      await nextTick();
      expect(wrapper.find('.related-items-tree.disabled-content').isVisible()).toBe(true);
    });

    it('renders tree header component', async () => {
      await nextTick();
      expect(wrapper.findComponent(RelatedItemsTreeHeader).isVisible()).toBe(true);
    });

    it('renders item add/create form container element', async () => {
      wrapper.vm.$store.dispatch('toggleAddItemForm', {
        toggleState: true,
        issuableType: TYPE_EPIC,
      });

      await nextTick();
      expect(wrapper.find('.add-item-form-container').isVisible()).toBe(true);
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
        wrapper.vm.$store.dispatch('toggleAddItemForm', {
          toggleState: true,
          issuableType,
        });
        wrapper.vm.$store.state.autoCompleteIssues = autoCompleteIssues;
        wrapper.vm.$store.state.autoCompleteEpics = autoCompleteEpics;

        await nextTick();

        expect(findAddItemForm().props()).toMatchObject({
          autoCompleteIssues: expectedAutoCompleteIssues,
          autoCompleteEpics: expectedAutoCompleteEpics,
        });
      },
    );

    it('switches tab to Roadmap', async () => {
      wrapper.vm.$store.state.itemsFetchResultEmpty = false;

      await nextTick();

      wrapper.findComponent(RelatedItemsTreeActions).vm.$emit('tab-change', ITEM_TABS.ROADMAP);

      await nextTick();

      expect(wrapper.vm.activeTab).toBe(ITEM_TABS.ROADMAP);
    });

    it.each`
      visibleApp        | activeTab
      ${'Tree View'}    | ${ITEM_TABS.TREE}
      ${'Roadmap View'} | ${ITEM_TABS.ROADMAP}
    `('renders $visibleApp when activeTab is $activeTab', async ({ activeTab }) => {
      wrapper.vm.$store.state.itemsFetchResultEmpty = false;

      await nextTick();

      wrapper.findComponent(RelatedItemsTreeActions).vm.$emit('tab-change', activeTab);

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
        wrapper.vm.$store.state.itemsFetchResultEmpty = false;

        await nextTick();

        wrapper.findComponent(RelatedItemsTreeHeader).vm.$emit('toggleRelatedItemsView', toggled);

        await nextTick();
        expect(wrapper.vm.showRelatedItems).toBe(toggled);
        expect(wrapper.findByTestId('related-items-container').exists()).toBe(toggled);
      },
    );
  });
});
