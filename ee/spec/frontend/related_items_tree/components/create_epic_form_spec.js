import { GlFormInput, GlButton, GlDropdownItem, GlDropdown, GlSearchBoxByType } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
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
        stubs: {
          GlDropdown,
          GlSearchBoxByType,
        },
      });
    };

    const findForm = () => wrapper.find('form');
    const findGlFormInput = () => wrapper.findComponent(GlFormInput);
    const findAllButtons = () => wrapper.findAllComponents(GlButton);
    const findSubmitButton = () => findAllButtons().at(0);
    const findCancelButton = () => findAllButtons().at(1);
    const findDropdown = () => wrapper.findComponent(GlDropdown);
    const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
    const findGlSearchBoxByType = () => wrapper.findComponent(GlSearchBoxByType);
    const findParentGroupItem = () => wrapper.findByTestId('parent-group-item');

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
          expect(wrapper.vm.isSubmitButtonDisabled).toBe(true);
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
          expect(findDropdown().props('text')).toBe(mockParentItem.groupName);
        });

        it('returns group name when a group is selected', () => {
          findAllDropdownItems().at(0).vm.$emit('click');
          expect(findDropdown().props('text')).toBe('GitLab Org');
        });
      });

      describe('canShowParentGroup', () => {
        it.each`
          searchTerm                  | expected
          ${undefined}                | ${true}
          ${'FooBar'}                 | ${false}
          ${mockParentItem.groupName} | ${true}
        `(
          'returns `$expected` when searchTerm is $searchTerm',
          async ({ searchTerm, expected }) => {
            createComponent();

            findGlSearchBoxByType().vm.$emit('input', searchTerm);
            await waitForPromises();

            expect(findParentGroupItem().exists()).toBe(expected);
          },
        );
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

          findDropdown().vm.$emit('show');

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
        expect(findAllDropdownItems().at(0).text()).toContain(mockParentItem.groupName);
      });
    });
  });
});
