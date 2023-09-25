import { GlFormInput, GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CreateEpicForm from 'ee/related_items_tree/components/create_epic_form.vue';
import createDefaultStore from 'ee/related_items_tree/store';

import { mockInitialConfig, mockParentItem } from '../mock_data';

Vue.use(Vuex);

describe('RelatedItemsTree', () => {
  describe('CreateEpicForm', () => {
    let wrapper;
    let mock;
    let store;

    const createComponent = (isSubmitting = false) => {
      store = createDefaultStore();

      store.dispatch('setInitialConfig', mockInitialConfig);
      store.dispatch('setInitialParentItem', mockParentItem);

      wrapper = shallowMountExtended(CreateEpicForm, {
        store,
        propsData: {
          isSubmitting,
        },
      });
    };

    const findForm = () => wrapper.find('form');
    const findGlFormInput = () => wrapper.findComponent(GlFormInput);
    const findAllButtons = () => wrapper.findAllComponents(GlButton);
    const findSubmitButton = () => findAllButtons().at(0);
    const findCancelButton = () => findAllButtons().at(1);
    const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);

    beforeEach(() => {
      mock = new MockAdapter(axios);
      createComponent();
    });

    afterEach(() => {
      mock.restore();
    });

    describe('computed', () => {
      describe('isSubmitButtonDisabled', () => {
        it('returns true when either `inputValue` prop is empty or `isSubmitting` prop is true', () => {
          expect(findSubmitButton().props('disabled')).toBe(true);
        });

        it('returns false when either `inputValue` prop is non-empty or `isSubmitting` prop is false', async () => {
          createComponent(false);
          findGlFormInput().vm.$emit('input', 'foo');

          await nextTick();
          expect(findSubmitButton().props('disabled')).toBe(false);
        });
      });

      describe('buttonLabel', () => {
        it('returns string "Creating epic" when `isSubmitting` prop is true', () => {
          createComponent(true);
          expect(findSubmitButton().text()).toBe('Creating epic');
        });

        it('returns string "Create epic" when `isSubmitting` prop is false', () => {
          expect(findSubmitButton().text()).toBe('Create epic');
        });
      });

      describe('dropdownPlaceholderText', () => {
        it('returns parent group name when no group is selected', () => {
          expect(findDropdown().props('toggleText')).toBe(mockParentItem.groupName);
        });

        it('returns group name when a group is selected', () => {
          findDropdown().vm.$emit('select', 1);
          expect(findDropdown().props('toggleText')).toBe('GitLab Org');
        });
      });

      describe('canShowParentGroup', () => {
        it.each`
          searchTerm                  | expectedLength
          ${undefined}                | ${1}
          ${'FooBar'}                 | ${0}
          ${mockParentItem.groupName} | ${1}
        `('has parent item after filtering', async ({ searchTerm, expectedLength }) => {
          createComponent();

          findDropdown().vm.$emit('search', searchTerm);
          await waitForPromises();

          expect(findDropdown().props('items')).toHaveLength(expectedLength);
        });
      });
    });

    describe('methods', () => {
      describe('onFormSubmit', () => {
        it('emits `createEpicFormSubmit` event on component with input value as param', () => {
          const value = 'foo';
          findGlFormInput().vm.$emit('input', value);

          findForm().trigger('submit');

          expect(wrapper.emitted('createEpicFormSubmit')).toHaveLength(1);
          expect(wrapper.emitted('createEpicFormSubmit')[0]).toEqual([
            {
              value,
              groupFullPath: undefined,
            },
          ]);
        });
      });

      describe('onFormCancel', () => {
        it('emits `createEpicFormCancel` event on component', () => {
          findCancelButton().vm.$emit('click');

          expect(wrapper.emitted('createEpicFormCancel')).toHaveLength(1);
        });
      });

      describe('handleDropdownShow', () => {
        it('fetches descendant groups based on searchTerm', () => {
          const handleDropdownShow = jest.spyOn(store, 'dispatch').mockImplementation(jest.fn());

          findDropdown().vm.$emit('shown');

          expect(handleDropdownShow).toHaveBeenCalledWith('fetchDescendantGroups', {
            groupId: undefined,
            search: '',
          });
        });
      });
    });

    describe('template', () => {
      it('renders input element within form', () => {
        expect(findGlFormInput().attributes('placeholder')).toBe('New epic title');
      });

      it('renders form action buttons', () => {
        expect(findSubmitButton().text()).toBe('Create epic');
        expect(findCancelButton().text()).toBe('Cancel');
      });

      it('renders parent group item as the first dropdown item', () => {
        expect(findDropdown().props('toggleText')).toContain(mockParentItem.groupName);
      });
    });
  });
});
