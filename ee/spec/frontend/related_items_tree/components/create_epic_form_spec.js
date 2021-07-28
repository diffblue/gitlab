import { GlFormInput, GlButton, GlDropdownItem } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';

import CreateEpicForm from 'ee/related_items_tree/components/create_epic_form.vue';
import createDefaultStore from 'ee/related_items_tree/store';

import { mockInitialConfig, mockParentItem } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = (isSubmitting = false) => {
  const store = createDefaultStore();

  store.dispatch('setInitialConfig', mockInitialConfig);
  store.dispatch('setInitialParentItem', mockParentItem);

  return shallowMount(CreateEpicForm, {
    localVue,
    store,
    propsData: {
      isSubmitting,
    },
  });
};

describe('RelatedItemsTree', () => {
  describe('CreateEpicForm', () => {
    let wrapper;
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
      mock.restore();
    });

    describe('computed', () => {
      describe('isSubmitButtonDisabled', () => {
        it('returns true when either `inputValue` prop is empty or `isSubmitting` prop is true', () => {
          expect(wrapper.vm.isSubmitButtonDisabled).toBe(true);
        });

        it('returns false when either `inputValue` prop is non-empty or `isSubmitting` prop is false', () => {
          const wrapperWithInput = createComponent(false);

          wrapperWithInput.setData({
            inputValue: 'foo',
          });

          return wrapperWithInput.vm.$nextTick(() => {
            expect(wrapperWithInput.vm.isSubmitButtonDisabled).toBe(false);

            wrapperWithInput.destroy();
          });
        });
      });

      describe('buttonLabel', () => {
        it('returns string "Creating epic" when `isSubmitting` prop is true', () => {
          const wrapperSubmitting = createComponent(true);

          return wrapperSubmitting.vm.$nextTick(() => {
            expect(wrapperSubmitting.vm.buttonLabel).toBe('Creating epic');

            wrapperSubmitting.destroy();
          });
        });

        it('returns string "Create epic" when `isSubmitting` prop is false', () => {
          expect(wrapper.vm.buttonLabel).toBe('Create epic');
        });
      });

      describe('dropdownPlaceholderText', () => {
        it('returns parent group name when no group is selected', () => {
          expect(wrapper.vm.dropdownPlaceholderText).toBe(mockParentItem.groupName);
        });

        it('returns group name when a group is selected', () => {
          const group = { name: 'Group 1' };
          wrapper.setData({ selectedGroup: group });
          expect(wrapper.vm.dropdownPlaceholderText).toBe(group.name);
        });
      });

      describe('canShowParentGroup', () => {
        it.each`
          searchTerm                  | expected
          ${undefined}                | ${true}
          ${'FooBar'}                 | ${false}
          ${mockParentItem.groupName} | ${true}
        `('returns `$expected` when searchTerm is $searchTerm', ({ searchTerm, expected }) => {
          wrapper.setData({ searchTerm });
          expect(wrapper.vm.canShowParentGroup).toBe(expected);
        });
      });
    });

    describe('methods', () => {
      describe('onFormSubmit', () => {
        it('emits `createEpicFormSubmit` event on component with input value as param', () => {
          const value = 'foo';
          wrapper.find(GlFormInput).vm.$emit('input', value);
          wrapper.vm.onFormSubmit();

          expect(wrapper.emitted().createEpicFormSubmit).toBeTruthy();
          expect(wrapper.emitted().createEpicFormSubmit[0]).toEqual([
            {
              value,
              groupFullPath: undefined,
            },
          ]);
        });
      });

      describe('onFormCancel', () => {
        it('emits `createEpicFormCancel` event on component', () => {
          wrapper.vm.onFormCancel();

          expect(wrapper.emitted().createEpicFormCancel).toBeTruthy();
        });
      });

      describe('handleDropdownShow', () => {
        it('fetches descendant groups based on searchTerm', () => {
          const handleDropdownShow = jest
            .spyOn(wrapper.vm, 'fetchDescendantGroups')
            .mockImplementation(jest.fn());

          wrapper.vm.handleDropdownShow();

          expect(handleDropdownShow).toHaveBeenCalledWith({
            groupId: mockParentItem.groupId,
            search: wrapper.vm.searchTerm,
          });
        });
      });
    });

    describe('template', () => {
      it('renders input element within form', () => {
        const inputEl = wrapper.find(GlFormInput);

        expect(inputEl.attributes('placeholder')).toBe('New epic title');
      });

      it('renders form action buttons', () => {
        const actionButtons = wrapper.findAll(GlButton);

        expect(actionButtons.at(0).text()).toBe('Create epic');
        expect(actionButtons.at(1).text()).toBe('Cancel');
      });

      it('renders parent group item as the first dropdown item', () => {
        const items = wrapper.findAll(GlDropdownItem);

        expect(items.at(0).text()).toContain(mockParentItem.groupName);
      });
    });
  });
});
