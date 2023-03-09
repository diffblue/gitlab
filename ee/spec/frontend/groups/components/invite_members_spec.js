import { GlFormInput, GlButton } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Component from 'ee/groups/components/invite_members.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

describe('User invites', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = extendedWrapper(
      shallowMount(Component, {
        propsData: {
          emails: [],
          docsPath: 'https://some.doc.path',
          ...propsData,
        },
      }),
    );
  };

  const inputs = () => wrapper.findAllComponents(GlFormInput);
  const addButton = () => wrapper.findComponent(GlButton);

  describe('Default state', () => {
    beforeEach(() => {
      createComponent();
    });
    const clickButton = () => addButton().vm.$emit('click');

    describe('Initial state', () => {
      it('creates input field', () => {
        expect(inputs().length).toBe(1);
      });

      it('does not set a value', () => {
        expect(inputs().at(0).attributes('value')).toBe(undefined);
      });
    });

    describe('With already filled emails', () => {
      const emails = ['a@a', 'b@b', 'c@c'];

      beforeEach(() => {
        createComponent({ emails, docsPath: 'https://some.doc.path' });
      });

      it('creates 3 input fields', () => {
        expect(inputs().length).toBe(3);
      });

      it.each([0, 1, 2])('restores the value of the passed emails', (index) => {
        expect(inputs().at(index).attributes('value')).toBe(emails[index]);
      });
    });

    describe('Adding an input', () => {
      beforeEach(() => {
        wrapper = mount(Component, {
          propsData: { emails: [], docsPath: 'https://some.doc.path' },
          attachTo: document.body,
        });

        clickButton();
      });

      it('adds an input field', () => {
        expect(inputs().length).toBe(2);
      });

      it.each([0, 1])('does not set a value', (index) => {
        expect(inputs().at(index).attributes('value')).toBe(undefined);
      });

      it('sets the focus to the new input field', () => {
        expect(inputs().at(1).element).toBe(document.activeElement);
      });
    });
  });

  describe('Configurable for multi-use', () => {
    it('number of initial inputs can be configured', () => {
      createComponent({ initialEmailInputs: 2 });

      expect(inputs().length).toBe(2);
    });

    it('placeholder can be configured', () => {
      createComponent({ emailPlaceholderPrefix: '_placeholder_' });

      expect(inputs().at(0).attributes('placeholder')).toBe('_placeholder_1@company.com');
    });

    it('input name can be configured', () => {
      createComponent({ inputName: 'emails[]' });

      expect(inputs().at(0).attributes('name')).toBe('emails[]');
    });

    it('adding another email button can be configured', () => {
      createComponent({ addAnotherText: '_addAnotherText_' });

      expect(addButton().text()).toBe('_addAnotherText_');
    });

    it('label for component can be configured', () => {
      createComponent({ inviteLabel: '_inviteLabel_' });

      expect(wrapper.findByTestId('no-input-form-group').attributes('label')).toBe('_inviteLabel_');
    });
  });
});
