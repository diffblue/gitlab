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
import { fetchUserIdsFromGroup } from 'ee/invite_members/utils';
import { noFreePlacesSubscription as mockSubscription } from '../mock_data';

jest.mock('ee/invite_members/check_overage', () => ({
  checkOverage: jest.fn().mockImplementation(() => ({ hasOverage: true, usersOverage: 2 })),
}));

jest.mock('ee/invite_members/get_subscription_data', () => ({
  fetchSubscription: jest.fn().mockImplementation(() => mockSubscription),
}));

jest.mock('ee/invite_members/utils', () => ({
  fetchUserIdsFromGroup: jest.fn().mockImplementation(() => [123, 256]),
}));

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
      attrs: {
        'access-levels': propsData.accessLevels,
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
  const findModal = () => wrapper.findComponent(GlModal);
  const findInitialModalContent = () => wrapper.findByTestId('invite-modal-initial-content');
  const findOverageModalContent = () => wrapper.findByTestId('invite-modal-overage-content');
  const findModalTitle = () => findModal().props('title');

  const emitEventFromModal = (eventName) => () =>
    findModal().vm.$emit(eventName, { preventDefault: jest.fn() });
  const clickInviteButton = emitEventFromModal('primary');
  const clickBackButton = emitEventFromModal('cancel');

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

      it('shows initial modal content', () => {
        expect(findInitialModalContent().isVisible()).toBe(true);
      });

      it('emits submit', () => {
        expect(wrapper.emitted('submit')).toEqual([[{ accessLevel: 10, expiresAt: undefined }]]);
      });
    });
  });

  describe('with overageMembersModal feature flag and a group to invite, and invite is clicked', () => {
    beforeEach(async () => {
      createComponent({ newGroupToInvite: 123 }, { glFeatures: { overageMembersModal: true } });
      clickInviteButton();
      await nextTick();
    });

    it('calls fetchUserIdsFromGroup and passes correct parameter', () => {
      expect(fetchUserIdsFromGroup).toHaveBeenCalledTimes(1);
      expect(fetchUserIdsFromGroup).toHaveBeenCalledWith(123);
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
      expect(findModal().props('actionPrimary')).toMatchObject({
        text: OVERAGE_MODAL_CONTINUE_BUTTON,
        attributes: {
          variant: 'confirm',
          disabled: false,
          loading: false,
          'data-qa-selector': 'invite_button',
        },
      });
    });

    it('renders the Continue button text correctly', () => {
      expect(findModal().props('actionCancel')).toMatchObject({
        text: OVERAGE_MODAL_BACK_BUTTON,
      });
    });

    it('shows the info text', () => {
      expect(findModal().text()).toContain(
        'If you continue, the _name_ group will have 2 seats in use and will be billed for the overage.',
      );
    });

    it('doesn\t show the initial modal content', () => {
      expect(findInitialModalContent().isVisible()).toBe(false);
    });

    describe('when switches back to the initial modal', () => {
      beforeEach(() => clickBackButton());

      it('shows the initial modal', () => {
        expect(findModal().props('title')).toBe(propsData.modalTitle);
        expect(findInitialModalContent().isVisible()).toBe(true);
      });

      it("doesn't show the overage content", () => {
        expect(findOverageModalContent().isVisible()).toBe(false);
      });
    });
  });
});
