import { GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import GlDropdownInput from 'ee/security_configuration/components/dropdown_input.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('DropdownInput component', () => {
  let wrapper;

  const option1 = {
    value: 'option1',
    text: 'Option 1',
  };
  const option2 = {
    value: 'option2',
    text: 'Option 2',
  };

  const testProps = {
    field: 'field',
    label: 'label',
    description: 'description',
    defaultValue: option1.value,
    defaultText: 'defaultText',
    value: option1.value,
    options: [option1, option2],
  };
  const newValue = 'foo';

  const createComponent = ({ props = {} } = {}) => {
    wrapper = extendedWrapper(
      mount(GlDropdownInput, {
        propsData: {
          ...props,
        },
      }),
    );
  };

  const findToggle = () => wrapper.find('button');
  const findLabel = () => wrapper.find('label');
  const findDescription = () => wrapper.findByTestId('dropdown-input-description');
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findRestoreDefaultLink = () => wrapper.findComponent(GlLink);

  describe('label', () => {
    describe('with a description', () => {
      beforeEach(() => {
        createComponent({
          props: testProps,
        });
      });

      it('renders the label', () => {
        expect(findLabel().text()).toContain(testProps.label);
      });

      it('renders the description', () => {
        const description = findDescription();

        expect(description.exists()).toBe(true);
        expect(description.text()).toBe(testProps.description);
      });
    });

    describe('without a description', () => {
      beforeEach(() => {
        createComponent({
          props: { ...testProps, description: '' },
        });
      });

      it('does not render the description', () => {
        expect(findDescription().exists()).toBe(false);
      });
    });
  });

  describe('section header', () => {
    it('does not render a section header by default', () => {
      createComponent({
        props: testProps,
      });

      expect(findListbox().props('headerText')).toBe('');
    });

    it('renders a section header when passed a sectionHeader prop', () => {
      const sectionHeader = 'Section header';
      createComponent({
        props: { ...testProps, sectionHeader },
      });

      expect(findListbox().props('headerText')).toBe(sectionHeader);
    });
  });

  describe('input', () => {
    beforeEach(() => {
      createComponent({
        props: testProps,
      });
    });

    it('sets the input to the value', () => {
      expect(findToggle().text()).toBe(option1.text);
    });

    it('is connected to the label', () => {
      expect(findListbox().attributes('id')).toBe(testProps.field);
      expect(findLabel().attributes('for')).toBe(testProps.field);
    });

    describe('when the user changes the value', () => {
      beforeEach(() => {
        findListbox().vm.$emit('select', option2.value);
      });

      it('emits an input event with the new value', () => {
        expect(wrapper.emitted('input')).toEqual([[option2.value]]);
      });
    });
  });

  describe('custom value message', () => {
    describe('given the value equals the default value', () => {
      beforeEach(() => {
        createComponent({
          props: testProps,
        });
      });

      it('does not display the custom value message', () => {
        expect(findRestoreDefaultLink().exists()).toBe(false);
      });
    });

    describe('given the value differs from the default value', () => {
      beforeEach(() => {
        createComponent({
          props: {
            ...testProps,
            value: newValue,
          },
        });
      });

      it('displays the custom value message', () => {
        expect(findRestoreDefaultLink().exists()).toBe(true);
      });

      describe('clicking on the restore default link', () => {
        beforeEach(() => {
          findRestoreDefaultLink().trigger('click');
        });

        it('emits an input event with the default value', () => {
          expect(wrapper.emitted('input')).toEqual([[testProps.defaultValue]]);
        });
      });

      describe('disabling the input', () => {
        beforeEach(async () => {
          await wrapper.setProps({ disabled: true });
        });

        it('does not display the custom value message', () => {
          expect(findRestoreDefaultLink().exists()).toBe(false);
        });
      });
    });
  });
});
