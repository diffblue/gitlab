import { GlDisclosureDropdown } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EpicHeaderActions from 'ee/epic/components/epic_header_actions.vue';
import { getStoreConfig } from 'ee/epic/store';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import DeleteIssueModal from '~/issues/show/components/delete_issue_modal.vue';
import issuesEventHub from '~/issues/show/event_hub';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import { mockEpicMeta, mockEpicData } from '../mock_data';

Vue.use(Vuex);
jest.mock('~/issues/show/event_hub', () => ({ $emit: jest.fn() }));

describe('EpicHeaderActions component', () => {
  let wrapper;
  let store;

  const getterSpies = {
    isEpicAuthor: jest.fn(() => false),
  };

  const createComponent = ({
    isLoggedIn = true,
    isMoveSidebarEnabled = false,
    state = {},
  } = {}) => {
    const { getters, ...storeConfig } = getStoreConfig();
    store = new Vuex.Store({
      ...storeConfig,
      getters: {
        ...getters,
        ...getterSpies,
      },
    });

    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', { ...mockEpicData, ...state });

    if (isLoggedIn) {
      window.gon.current_user_id = 1;
    }

    wrapper = mountExtended(EpicHeaderActions, {
      store,
      provide: {
        fullPath: 'mock-path',
        iid: 'mock-iid',
        reportAbusePath: '/report/abuse/path',
        glFeatures: {
          movedMrSidebar: isMoveSidebarEnabled,
        },
      },
    });
  };

  const modalId = 'delete-modal-id';

  const findCloseEpicButton = () => wrapper.findByRole('button', { name: 'Close epic' });
  const findCopyReferenceDropdownItem = () =>
    wrapper.findByRole('button', { name: 'Copy reference' });
  const findDeleteEpicButton = () => wrapper.findByRole('button', { name: 'Delete epic' });
  const findDeleteEpicModal = () => wrapper.findComponent(DeleteIssueModal);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findEditButton = () => wrapper.findByRole('button', { name: 'Edit title and description' });
  const findNewEpicButton = () => wrapper.findByRole('link', { name: 'New epic' });
  const findNotificationToggle = () => wrapper.findComponent(SidebarSubscriptionsWidget);
  const findReopenEpicButton = () => wrapper.findByRole('button', { name: 'Reopen epic' });

  const findActionsDropdownMobile = () => wrapper.findByTestId('actions-dropdown-mobile');
  const findActionsDropdownDesktop = () => wrapper.findByTestId('actions-dropdown-desktop');

  const findReportAbuseButton = () =>
    wrapper.findByRole('button', { name: 'Report abuse to administrator' });
  const findAbuseCategorySelector = () => wrapper.findComponent(AbuseCategorySelector);

  describe('edit button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders', () => {
      expect(findEditButton().exists()).toBe(true);
    });

    it('does not emit "open.form" event when not clicked', () => {
      expect(issuesEventHub.$emit).not.toHaveBeenCalled();
    });

    it('emits "open.form" event when clicked', async () => {
      await findEditButton().trigger('click');

      expect(issuesEventHub.$emit).toHaveBeenCalledWith('open.form');
    });
  });

  describe('close/reopen button', () => {
    describe('when epic is open', () => {
      beforeEach(() => {
        createComponent({ state: { state: STATUS_OPEN } });
      });

      it('renders `Close epic` text', () => {
        expect(findCloseEpicButton().text()).toBe('Close epic');
      });
    });

    describe('when epic is closed', () => {
      beforeEach(() => {
        createComponent({ state: { state: STATUS_CLOSED } });
      });

      it('renders `Reopen epic` text', () => {
        expect(findReopenEpicButton().text()).toBe('Reopen epic');
      });
    });
  });

  describe('actions dropdown', () => {
    describe('new epic dropdown item', () => {
      it('does not render if user cannot create epics', () => {
        createComponent({ state: { canCreate: false } });

        expect(findNewEpicButton().exists()).toBe(false);
      });

      it('renders if user can create epics', () => {
        createComponent({ state: { canCreate: true } });

        expect(findNewEpicButton().exists()).toBe(true);
      });
    });

    describe('delete epic dropdown item', () => {
      it('does not render if user cannot create epics', () => {
        createComponent({ state: { canDestroy: false } });

        expect(findDeleteEpicButton().exists()).toBe(false);
      });

      it('renders if user can create epics', () => {
        createComponent({ state: { canDestroy: true } });

        expect(findDeleteEpicButton().exists()).toBe(true);
      });
    });

    describe('moved_mr_sidebar feature flag', () => {
      describe('when the flag is off', () => {
        beforeEach(() => {
          createComponent({ isMoveSidebarEnabled: false });
        });

        it('does not render notification toggle', () => {
          expect(findNotificationToggle().exists()).toBe(false);
        });

        it('does not render the copy reference dropdown item', () => {
          expect(findCopyReferenceDropdownItem().exists()).toBe(false);
        });

        it('does not pass bordered property to actions dropdown', () => {
          expect(findActionsDropdownMobile().props('bordered')).toBe(false);
          expect(findActionsDropdownDesktop().props('bordered')).toBe(false);
        });
      });

      describe('when the flag is on', () => {
        beforeEach(() => {
          createComponent({ isMoveSidebarEnabled: true });
        });

        it('renders the notification toggle', () => {
          expect(findNotificationToggle().exists()).toBe(true);
        });

        it('renders the copy reference dropdown item', () => {
          expect(findCopyReferenceDropdownItem().exists()).toBe(true);
        });

        it('pass bordered property to actions dropdown', () => {
          expect(findActionsDropdownMobile().props('bordered')).toBe(true);
          expect(findActionsDropdownDesktop().props('bordered')).toBe(true);
        });
      });
    });

    describe('when logged out', () => {
      describe.each`
        movedMrSidebarEnabled | headerActionsVisible
        ${true}               | ${true}
        ${false}              | ${false}
      `(
        `when movedMrSidebar feature flag is "$movedMrSidebarEnabled"`,
        ({ movedMrSidebarEnabled, headerActionsVisible }) => {
          beforeEach(() => {
            createComponent({
              isLoggedIn: false,
              isMoveSidebarEnabled: movedMrSidebarEnabled,
              state: {
                canCreate: false,
                canDestroy: false,
                canUpdate: false,
              },
            });
          });

          it(`${headerActionsVisible ? 'shows' : 'hides'} actions dropdown`, () => {
            expect(findDropdown().exists()).toBe(headerActionsVisible);
          });

          it(`${headerActionsVisible ? 'shows' : 'hides'} "Copy reference" dropdown item`, () => {
            expect(findCopyReferenceDropdownItem().exists()).toBe(headerActionsVisible);
          });

          it('does not show notification toggle', () => {
            expect(findNotificationToggle().exists()).toBe(false);
          });
        },
      );
    });
  });

  describe('delete issue modal', () => {
    it('renders', () => {
      createComponent();

      expect(findDeleteEpicModal().props()).toEqual({
        issuePath: '',
        issueType: 'epic',
        modalId,
        title: 'Delete epic',
      });
    });
  });

  describe('report abuse to admin button', () => {
    describe('when the logged in user is not the epic author', () => {
      beforeEach(() => {
        getterSpies.isEpicAuthor = jest.fn(() => false);

        createComponent();
      });

      it('renders the button but not the abuse category drawer', () => {
        expect(findReportAbuseButton().exists()).toBe(true);
        expect(findAbuseCategorySelector().exists()).toEqual(false);
      });

      it('opens the abuse category drawer', async () => {
        await findReportAbuseButton().trigger('click');

        expect(findAbuseCategorySelector().props()).toMatchObject({
          showDrawer: true,
          reportedUserId: mockEpicMeta.author.id,
          reportedFromUrl: mockEpicMeta.webUrl,
        });
      });

      it('closes the abuse category drawer', async () => {
        await findReportAbuseButton().trigger('click');
        expect(findAbuseCategorySelector().exists()).toEqual(true);

        await findAbuseCategorySelector().vm.$emit('close-drawer');
        expect(findAbuseCategorySelector().exists()).toEqual(false);
      });
    });

    describe('when the logged in user is the epic author', () => {
      beforeEach(() => {
        getterSpies.isEpicAuthor = jest.fn(() => true);

        createComponent();
      });

      it('does not render the button', () => {
        expect(findReportAbuseButton().exists()).toBe(false);
      });
    });
  });
});
