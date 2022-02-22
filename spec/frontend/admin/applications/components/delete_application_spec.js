import { GlButton, GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import DeleteApplication from '~/admin/applications/components/delete_application.vue';

const modalID = 'fake-id';
const path = 'application/path/1';
const name = 'Application name';

jest.mock('lodash/uniqueId', () => () => 'fake-id');
jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('DeleteApplication', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(DeleteApplication, {
      provide: {
        path,
        name,
      },
      directives: {
        GlModal: createMockDirective(),
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.find('form');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('the button component', () => {
    it('displays the destroy button', () => {
      const button = findButton();

      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Destroy');
    });

    it('contains the correct modal ID', () => {
      const buttonModalId = getBinding(findButton().element, 'gl-modal').value;

      expect(buttonModalId).toBe(modalID);
    });
  });

  describe('the modal component', () => {
    it('displays the modal component', () => {
      const modal = findModal();

      expect(modal.exists()).toBe(true);
      expect(modal.props('title')).toBe('Confirm destroy application');
      expect(modal.text()).toBe(`Are you sure that you want to destroy ${name}`);
    });

    it('contains the correct modal ID', () => {
      expect(findModal().props('modalId')).toBe(modalID);
    });

    describe('form', () => {
      it('matches the snapshot', () => {
        expect(findForm().element).toMatchSnapshot();
      });

      describe('form submission', () => {
        let formSubmitSpy;

        beforeEach(() => {
          formSubmitSpy = jest.spyOn(wrapper.vm.$refs.deleteForm, 'submit');
          findModal().vm.$emit('primary');
        });

        it('submits the form on the modal primary action', () => {
          expect(formSubmitSpy).toHaveBeenCalled();
        });
      });
    });
  });
});
