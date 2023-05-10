import { shallowMount } from '@vue/test-utils';
import TableActions from 'ee/groups/settings/compliance_frameworks/components/table_actions.vue';
import {
  OPTIONS_BUTTON_LABEL,
  DELETE_BUTTON_LABEL,
  EDIT_BUTTON_LABEL,
  SET_DEFAULT_BUTTON_LABEL,
  REMOVE_DEFAULT_BUTTON_LABEL,
} from 'ee/groups/settings/compliance_frameworks/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { framework, defaultFramework } from '../mock_data';

describe('TableActions', () => {
  let wrapper;

  const findEditButton = () => wrapper.findByTestId('compliance-framework-edit-button');
  const findDropdownButton = () => wrapper.findByTestId('compliance-framework-dropdown-button');
  const findDeleteButton = () => wrapper.findByTestId('compliance-framework-delete-button');
  const findSetDefaultButton = () =>
    wrapper.findByTestId('compliance-framework-set-default-button');
  const findRemoveDefaultButton = () =>
    wrapper.findByTestId('compliance-framework-remove-default-button');

  const createComponent = (props = {}, provide = {}) => {
    wrapper = extendedWrapper(
      shallowMount(TableActions, {
        propsData: {
          framework,
          loading: false,
          ...props,
        },
        directives: {
          GlTooltip: createMockDirective('gl-tooltip'),
        },
        provide: {
          canAddEdit: true,
          ...provide,
        },
      }),
    );
  };

  const displaysTheButton = (button, icon, ariaLabel) => {
    expect(button.props('icon')).toBe(icon);
    expect(button.props('disabled')).toBe(false);
    expect(button.props('loading')).toBe(false);
    expect(button.attributes('aria-label')).toBe(ariaLabel);
  };

  it('does not show modification buttons when editing is unavailable', () => {
    createComponent({}, { canAddEdit: false });

    expect(findEditButton().exists()).toBe(false);
    expect(findDropdownButton().exists()).toBe(false);
  });

  it('displays the edit button', () => {
    createComponent();

    const button = findEditButton();

    displaysTheButton(button, 'pencil', EDIT_BUTTON_LABEL);
  });

  it('emits an "edit" event when clicked', () => {
    createComponent();

    const button = findEditButton();

    button.vm.$emit('click', new MouseEvent('click'));

    expect(wrapper.emitted('edit')).toHaveLength(1);
    expect(wrapper.emitted('edit')[0][0]).toMatchObject(framework);
  });

  it('displays a dropdown Button', () => {
    createComponent();

    const button = findDropdownButton();
    const tooltip = getBinding(button.element, 'gl-tooltip');

    displaysTheButton(button, 'ellipsis_v', OPTIONS_BUTTON_LABEL);
    expect(tooltip.value).toBe('Options');
  });

  describe('when a framework is default', () => {
    beforeEach(() => {
      createComponent({ framework: defaultFramework });
    });

    it('displays a remove default button', () => {
      expect(findRemoveDefaultButton().text()).toBe(REMOVE_DEFAULT_BUTTON_LABEL);
      expect(findRemoveDefaultButton().attributes('aria-label')).toBe(REMOVE_DEFAULT_BUTTON_LABEL);
    });

    it('emits "removeDefault" event when the remove default button is clicked', () => {
      findRemoveDefaultButton().vm.$emit('click');
      expect(wrapper.emitted('removeDefault')[0]).toStrictEqual([
        { framework: defaultFramework, defaultVal: false },
      ]);
    });
  });

  describe('when a framework is not default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays a set default button', () => {
      expect(findSetDefaultButton().text()).toBe(SET_DEFAULT_BUTTON_LABEL);
      expect(findSetDefaultButton().attributes('aria-label')).toBe(SET_DEFAULT_BUTTON_LABEL);
    });

    it('emits "setDefault" event when the set default button is clicked', () => {
      findSetDefaultButton().vm.$emit('click');

      expect(wrapper.emitted('setDefault')[0]).toStrictEqual([{ framework, defaultVal: true }]);
    });

    it('displays a delete button', () => {
      expect(findDeleteButton().text()).toBe(DELETE_BUTTON_LABEL);
      expect(findDeleteButton().attributes('aria-label')).toBe(DELETE_BUTTON_LABEL);
    });

    it('emits "delete" event when the delete button is clicked', () => {
      findDeleteButton().vm.$emit('click');

      expect(wrapper.emitted('delete')[0]).toStrictEqual([framework]);
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('disables the dropdown button and shows loading', () => {
      const button = findDropdownButton();

      expect(button.props('disabled')).toBe(true);
      expect(button.props('loading')).toBe(false);
    });

    it('disables the edit button and does not show loading', () => {
      const button = findEditButton();

      expect(button.props('disabled')).toBe(true);
      expect(button.props('loading')).toBe(false);
    });
  });
});
