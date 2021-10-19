import { GlModal, GlSprintf } from '@gitlab/ui';
import {
  CONFIRM_DANGER_WARNING,
  CONFIRM_DANGER_MODAL_BUTTON,
} from '~/vue_shared/components/confirm_danger/constants';
import ConfirmDangerModal from '~/vue_shared/components/confirm_danger/confirm_danger_modal.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Confirm Danger Modal', () => {
  const confirmDangerMessage = 'This is a dangerous activity';
  const confirmButtonText = 'Confirm button text';
  const phrase = 'all your bases are belong to us';
  const modalId = 'confirm-danger-modal';

  let wrapper;

  const findGlModal = () => wrapper.findComponent(GlModal);
  const findConfirmationPhrase = () => wrapper.findByTestId('confirm-danger-phrase');
  const findConfirmationInput = () => wrapper.findByTestId('confirm-danger-input');
  const findDefaultWarning = () => wrapper.findByTestId('confirm-danger-warning');
  const findAdditionalMessage = () => wrapper.findByTestId('confirm-danger-message');
  const findPrimaryAction = () => findGlModal().props('actionPrimary');
  const findPrimaryActionAttributes = (attr) => findPrimaryAction().attributes[0][attr];

  const createComponent = ({ provide = {} } = {}) =>
    shallowMountExtended(ConfirmDangerModal, {
      propsData: {
        modalId,
        phrase,
      },
      provide,
      stubs: { GlSprintf },
    });

  beforeEach(() => {
    wrapper = createComponent({ provide: { confirmDangerMessage, confirmButtonText } });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the default warning message', () => {
    expect(findDefaultWarning().text()).toBe(CONFIRM_DANGER_WARNING);
  });

  it('renders any additional messages', () => {
    expect(findAdditionalMessage().text()).toBe(confirmDangerMessage);
  });

  it('renders the confirm button', () => {
    expect(findPrimaryAction().text).toBe(confirmButtonText);
    expect(findPrimaryActionAttributes('variant')).toBe('danger');
  });

  it('renders the correct confirmation phrase', () => {
    expect(findConfirmationPhrase().text()).toBe(
      `Please type ${phrase} to proceed or close this modal to cancel.`,
    );
  });

  describe('without injected data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('does not render any additional messages', () => {
      expect(findAdditionalMessage().exists()).toBe(false);
    });

    it('renders the default confirm button', () => {
      expect(findPrimaryAction().text).toBe(CONFIRM_DANGER_MODAL_BUTTON);
    });
  });

  describe('with a valid confirmation phrase', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('enables the confirm button', async () => {
      expect(findPrimaryActionAttributes('disabled')).toBe(true);

      await findConfirmationInput().vm.$emit('input', phrase);

      expect(findPrimaryActionAttributes('disabled')).toBe(false);
    });

    it('emits a `confirm` event when the button is clicked', async () => {
      expect(wrapper.emitted('confirm')).toBeUndefined();

      await findConfirmationInput().vm.$emit('input', phrase);
      await findGlModal().vm.$emit('primary');

      expect(wrapper.emitted('confirm')).not.toBeUndefined();
    });
  });
});
