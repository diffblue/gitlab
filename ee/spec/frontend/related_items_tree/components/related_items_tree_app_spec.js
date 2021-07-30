import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';

import CreateIssueForm from 'ee/related_items_tree/components/create_issue_form.vue';
import RelatedItemsTreeApp from 'ee/related_items_tree/components/related_items_tree_app.vue';
import RelatedItemsTreeHeader from 'ee/related_items_tree/components/related_items_tree_header.vue';
import createDefaultStore from 'ee/related_items_tree/store';
import { getJSONFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import { issuableTypesMap } from '~/related_issues/constants';

import { mockInitialConfig, mockParentItem, mockEpics, mockIssues } from '../mock_data';

const mockProjects = getJSONFixture('static/projects.json');

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = () => {
  const store = createDefaultStore();

  store.dispatch('setInitialConfig', mockInitialConfig);
  store.dispatch('setInitialParentItem', mockParentItem);
  store.dispatch('setItemChildren', {
    parentItem: mockParentItem,
    children: [...mockEpics, ...mockIssues],
  });

  return shallowMount(RelatedItemsTreeApp, {
    localVue,
    store,
  });
};

describe('RelatedItemsTreeApp', () => {
  let axiosMock;
  let wrapper;

  const findCreateIssueForm = () => wrapper.find(CreateIssueForm);

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(mockInitialConfig.projectsEndpoint).replyOnce(200, mockProjects);
  });

  afterEach(() => {
    wrapper.destroy();
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

    it('renders loading icon when `state.itemsFetchInProgress` prop is true', () => {
      wrapper.vm.$store.dispatch('requestItems', {
        parentItem: mockParentItem,
        isSubItem: false,
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(GlLoadingIcon).isVisible()).toBe(true);
      });
    });

    it('renders tree container element when `state.itemsFetchInProgress` prop is false', () =>
      wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('.related-items-tree').isVisible()).toBe(true);
      }));

    it('renders tree container element with `disabled-content` class when `state.itemsFetchInProgress` prop is false and `state.itemAddInProgress` or `state.itemCreateInProgress` is true', () => {
      wrapper.vm.$store.dispatch('requestAddItem');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('.related-items-tree.disabled-content').isVisible()).toBe(true);
      });
    });

    it('renders tree header component', () =>
      wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(RelatedItemsTreeHeader).isVisible()).toBe(true);
      }));

    it('renders item add/create form container element', () => {
      wrapper.vm.$store.dispatch('toggleAddItemForm', {
        toggleState: true,
        issuableType: issuableTypesMap.Epic,
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('.add-item-form-container').isVisible()).toBe(true);
      });
    });

    it('does not render create issue form', () => {
      expect(findCreateIssueForm().exists()).toBe(false);
    });
  });
});
