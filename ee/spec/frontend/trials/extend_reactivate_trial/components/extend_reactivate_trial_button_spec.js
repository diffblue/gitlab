import { GlButton, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ExtendReactivateTrialButton from 'ee/trials/extend_reactivate_trial/components/extend_reactivate_trial_button.vue';
import {
  i18n,
  TRIAL_ACTION_EXTEND,
  TRIAL_ACTION_REACTIVATE,
} from 'ee/trials/extend_reactivate_trial/constants';
import { sprintf } from '~/locale';

describe('ExtendReactivateTrialButton', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    return shallowMount(ExtendReactivateTrialButton, {
      propsData: {
        ...props,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(GlModal);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent({
        namespaceId: 1,
        action: TRIAL_ACTION_EXTEND,
        planName: 'Ultimate',
      });
    });

    it('does not have loading icon', () => {
      expect(findButton().props('loading')).toBe(false);
    });
  });

  describe('when extending trial', () => {
    beforeEach(() => {
      wrapper = createComponent({
        namespaceId: 1,
        action: TRIAL_ACTION_EXTEND,
        planName: 'Ultimate',
      });
    });

    it('has the "Extend trial" text on the button', () => {
      expect(findButton().text()).toBe(i18n.extend.buttonText);
    });

    it('has the correct text in the modal', () => {
      expect(findModal().text()).toBe(
        sprintf(i18n.extend.modalText, { planName: 'Ultimate plan' }),
      );
    });
  });

  describe('when reactivating trial', () => {
    beforeEach(() => {
      wrapper = createComponent({
        namespaceId: 1,
        action: TRIAL_ACTION_REACTIVATE,
        planName: 'Ultimate',
      });
    });

    it('has the "Reactivate trial" text on the button', () => {
      expect(findButton().text()).toBe(i18n.reactivate.buttonText);
    });

    it('has the correct text in the modal', () => {
      expect(findModal().text()).toBe(
        sprintf(i18n.reactivate.modalText, { planName: 'Ultimate plan' }),
      );
    });
  });
});
