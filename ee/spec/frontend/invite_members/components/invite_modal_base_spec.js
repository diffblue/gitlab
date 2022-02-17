import {
  GlDropdown,
  GlDropdownItem,
  GlDatepicker,
  GlFormGroup,
  GlSprintf,
  GlLink,
  GlModal,
} from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InviteModalBase from 'ee_else_ce/invite_members/components/invite_modal_base.vue';
import { CANCEL_BUTTON_TEXT, INVITE_BUTTON_TEXT } from '~/invite_members/constants';
import {
  OVERAGE_MODAL_TITLE,
  OVERAGE_MODAL_CONTINUE_BUTTON,
  OVERAGE_MODAL_BACK_BUTTON,
} from 'ee/invite_members/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { propsData } from 'jest/invite_members/mock_data/modal_base';

describe('InviteModalBase', () => {
  let wrapper;

  const createComponent = (data = {}, props = {}, glFeatures = {}) => {
    wrapper = shallowMountExtended(InviteModalBase, {
      propsData: {
        ...propsData,
        ...props,
      },
      provide: {
        ...glFeatures,
      },
      data() {
        return data;
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
        GlDropdown: true,
        GlDropdownItem: true,
        GlSprintf,
        GlFormGroup: stubComponent(GlFormGroup, {
          props: ['state', 'invalidFeedback', 'description'],
        }),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => findDropdown().findAllComponents(GlDropdownItem);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);
  const findLink = () => wrapper.findComponent(GlLink);
  const findIntroText = () => wrapper.findByTestId('modal-base-intro-text').text();
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findInviteButton = () => wrapper.findByTestId('invite-button');
  const findBackButton = () => wrapper.findByTestId('overage-back-button');
  const findOverageInviteButton = () => wrapper.findByTestId('invite-with-overage-button');

  const clickInviteButton = () => findInviteButton().vm.$emit('click');
  const clickBackButton = () => findBackButton().vm.$emit('click');

  describe('rendering the modal', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the modal with the correct title', () => {
      expect(wrapper.findComponent(GlModal).props('title')).toBe(propsData.modalTitle);
    });

    it('displays the introText', () => {
      expect(findIntroText()).toBe(propsData.labelIntroText);
    });

    it('renders the Cancel button text correctly', () => {
      expect(findCancelButton().text()).toBe(CANCEL_BUTTON_TEXT);
    });

    it('renders the Invite button text correctly', () => {
      expect(findInviteButton().text()).toBe(INVITE_BUTTON_TEXT);
    });

    it('renders the Invite button modal without isLoading', () => {
      expect(findInviteButton().props('loading')).toBe(false);
    });

    describe('rendering the access levels dropdown', () => {
      it('sets the default dropdown text to the default access level name', () => {
        expect(findDropdown().attributes('text')).toBe('Guest');
      });

      it('renders dropdown items for each accessLevel', () => {
        expect(findDropdownItems()).toHaveLength(5);
      });
    });

    describe('rendering the help link', () => {
      it('renders the correct link', () => {
        expect(findLink().attributes('href')).toBe(propsData.helpLink);
      });
    });

    describe('rendering the access expiration date field', () => {
      it('renders the datepicker', () => {
        expect(findDatepicker().exists()).toBe(true);
      });
    });
  });

  describe('displays overage modal', () => {
    beforeEach(async () => {
      createComponent({}, {}, { glFeatures: { overageMembersModal: true } });
      clickInviteButton();

      await waitForPromises();
    });

    it('renders the modal with the correct title', () => {
      expect(wrapper.findComponent(GlModal).props('title')).toBe(OVERAGE_MODAL_TITLE);
    });

    it('renders the Back button text correctly', () => {
      expect(findBackButton().text()).toBe(OVERAGE_MODAL_BACK_BUTTON);
    });

    it('renders the Continue button text correctly', () => {
      expect(findOverageInviteButton().text()).toBe(OVERAGE_MODAL_CONTINUE_BUTTON);
    });

    it('shows the info text', () => {
      expect(wrapper.findComponent(GlModal).text()).toContain(
        'If you continue, the _name_ group will have 1 seat in use and will be billed for the overage.',
      );
    });

    it('switches back to the intial modal', async () => {
      clickBackButton();
      await waitForPromises();

      expect(wrapper.findComponent(GlModal).props('title')).toBe('_modal_title_');
    });
  });
});
