import { GlModal, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContentTransition from '~/vue_shared/components/content_transition.vue';
import CEInviteModalBase from '~/invite_members/components/invite_modal_base.vue';
import EEInviteModalBase from 'ee/invite_members/components/invite_modal_base.vue';
import {
  OVERAGE_MODAL_TITLE,
  OVERAGE_MODAL_CONTINUE_BUTTON,
  OVERAGE_MODAL_BACK_BUTTON,
} from 'ee/invite_members/constants';
import { propsData } from 'jest/invite_members/mock_data/modal_base';

describe('EEInviteModalBase', () => {
  let wrapper;
  let listenerSpy;

  const createComponent = (props = {}, glFeatures = {}) => {
    wrapper = shallowMountExtended(EEInviteModalBase, {
      propsData: {
        ...propsData,
        ...props,
      },
      provide: {
        ...glFeatures,
      },
      stubs: {
        GlSprintf,
        InviteModalBase: CEInviteModalBase,
        ContentTransition,
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
      listeners: {
        submit: (...args) => listenerSpy('submit', ...args),
        reset: (...args) => listenerSpy('reset', ...args),
        foo: (...args) => listenerSpy('foo', ...args),
      },
    });
  };

  beforeEach(() => {
    listenerSpy = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findCEBase = () => wrapper.findComponent(CEInviteModalBase);
  const findInviteButton = () => wrapper.findByTestId('invite-button');
  const findBackButton = () => wrapper.findByTestId('overage-back-button');
  const findInitialModalContent = () => wrapper.findByTestId('invite-modal-initial-content');
  const findOverageModalContent = () => wrapper.findByTestId('invite-modal-overage-content');
  const findModalTitle = () => wrapper.findComponent(GlModal).props('title');

  const clickInviteButton = () => findInviteButton().vm.$emit('click');
  const clickBackButton = () => findBackButton().vm.$emit('click');

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('passes attrs to CE base', () => {
      expect(findCEBase().props()).toMatchObject({
        ...propsData,
        currentSlot: 'default',
        extraSlots: EEInviteModalBase.EXTRA_SLOTS,
      });
    });

    it("doesn't show the overage content", () => {
      expect(findOverageModalContent().isVisible()).toBe(false);
    });

    it('when reset is emitted on base, emits reset', () => {
      expect(wrapper.emitted('reset')).toBeUndefined();

      findCEBase().vm.$emit('reset');

      expect(wrapper.emitted('reset')).toHaveLength(1);
    });

    describe('(integration) when invite is clicked', () => {
      beforeEach(async () => {
        clickInviteButton();
        await nextTick();
      });

      it('does not change title', () => {
        expect(findModalTitle()).toBe(propsData.modalTitle);
      });

      it('does not show back button', () => {
        expect(findBackButton().exists()).toBe(false);
      });

      it('shows initial modal content', () => {
        expect(findInitialModalContent().isVisible()).toBe(true);
      });

      it('emits submit', () => {
        expect(wrapper.emitted('submit')).toEqual([[{ accessLevel: 10, expiresAt: undefined }]]);
      });
    });
  });

  describe('with overageMembersModal feature flag, and invite is clicked ', () => {
    beforeEach(async () => {
      createComponent({}, { glFeatures: { overageMembersModal: true } });
      clickInviteButton();
      await nextTick();
    });

    it('does not emit submit', () => {
      expect(wrapper.emitted().submit).toBeUndefined();
    });

    it('renders the modal with the correct title', () => {
      expect(findModalTitle()).toBe(OVERAGE_MODAL_TITLE);
    });

    it('renders the Back button text correctly', () => {
      expect(findBackButton().text()).toBe(OVERAGE_MODAL_BACK_BUTTON);
    });

    it('renders the Continue button text correctly', () => {
      expect(findInviteButton().text()).toBe(OVERAGE_MODAL_CONTINUE_BUTTON);
    });

    it('shows the info text', () => {
      expect(wrapper.findComponent(GlModal).text()).toContain(
        'If you continue, the _name_ group will have 1 seat in use and will be billed for the overage.',
      );
    });

    it('doesn\t show the initial modal content', () => {
      expect(findInitialModalContent().isVisible()).toBe(false);
    });

    describe('when switches back to the initial modal', () => {
      beforeEach(() => clickBackButton());

      it('shows the initial modal', () => {
        expect(wrapper.findComponent(GlModal).props('title')).toBe(propsData.modalTitle);
        expect(findInitialModalContent().isVisible()).toBe(true);
      });

      it("doesn't show the overage content", () => {
        expect(findOverageModalContent().isVisible()).toBe(false);
      });
    });
  });
});
