import { GlIcon, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import EpicHeader from 'ee/epic/components/epic_header.vue';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import DeleteIssueModal from '~/issues/show/components/delete_issue_modal.vue';
import createStore from 'ee/epic/store';
import waitForPromises from 'helpers/wait_for_promises';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import issuesEventHub from '~/issues/show/event_hub';

import createMockApollo from 'helpers/mock_apollo_helper';
import epicReferenceQuery from '~/sidebar/queries/epic_reference.query.graphql';
import { mockEpicMeta, mockEpicData, mockEpicReferenceData } from '../mock_data';

jest.mock('~/issues/show/event_hub', () => ({ $emit: jest.fn() }));

describe('EpicHeaderComponent', () => {
  let wrapper;
  let store;

  const epicReferenceSuccessHandler = jest.fn().mockResolvedValue(mockEpicReferenceData);

  Vue.use(VueApollo);

  const createComponent = ({ isMoveSidebarEnabled = false } = {}) => {
    store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    const handlers = [[epicReferenceQuery, epicReferenceSuccessHandler]];

    wrapper = shallowMount(EpicHeader, {
      apolloProvider: createMockApollo(handlers),
      store,
      provide: {
        fullPath: 'mock-path',
        iid: 'mock-iid',
        glFeatures: {
          movedMrSidebar: isMoveSidebarEnabled,
        },
      },
      stubs: {
        GlButton,
      },
    });
  };

  const modalId = 'delete-modal-id';

  const findModal = () => wrapper.findComponent(DeleteIssueModal);
  const findStatusBox = () => wrapper.find('[data-testid="status-box"]');
  const findStatusIcon = () => wrapper.find('[data-testid="status-icon"]');
  const findStatusText = () => wrapper.find('[data-testid="status-text"]');
  const findConfidentialIcon = () => wrapper.find('[data-testid="confidential-icon"]');
  const findAuthorDetails = () => wrapper.find('[data-testid="author-details"]');
  const findActionButtons = () => wrapper.find('[data-testid="action-buttons"]');
  const findToggleStatusButton = () => wrapper.find('[data-testid="toggle-status-button"]');
  const findEditButton = () => wrapper.find('[data-testid="edit-button"]');
  const findNewEpicButton = () => wrapper.find('[data-testid="new-epic-button"]');
  const findDeleteEpicButton = () => wrapper.find('[data-testid="delete-epic-button"]');
  const findSidebarToggle = () => wrapper.find('[data-testid="sidebar-toggle"]');
  const findNotificationWidget = () => wrapper.find(`[data-testid="notification-toggle"]`);
  const findCopyRefenceDropdownItem = () => wrapper.find(`[data-testid="copy-reference"]`);

  describe('computed', () => {
    describe('statusIcon', () => {
      it('returns string `issue-open-m` when `isEpicOpen` is true', () => {
        createComponent();
        store.state.state = STATUS_OPEN;

        expect(findStatusIcon().props('name')).toBe('epic');
      });

      it('returns string `mobile-issue-close` when `isEpicOpen` is false', async () => {
        createComponent();
        store.state.state = STATUS_CLOSED;

        await nextTick();
        expect(findStatusIcon().props('name')).toBe('epic-closed');
      });
    });

    describe('statusText', () => {
      it('returns string `Open` when `isEpicOpen` is true', () => {
        createComponent();
        store.state.state = STATUS_OPEN;

        expect(findStatusText().text()).toBe('Open');
      });

      it('returns string `Closed` when `isEpicOpen` is false', async () => {
        createComponent();
        store.state.state = STATUS_CLOSED;

        await nextTick();
        expect(findStatusText().text()).toBe('Closed');
      });
    });

    describe('actionButtonClass', () => {
      it('returns `btn-close` when `isEpicOpen` is true', () => {
        createComponent();
        store.state.state = STATUS_OPEN;

        expect(findToggleStatusButton().classes()).toContain('btn-close');
      });

      it('returns `btn-open` when `isEpicOpen` is false', async () => {
        createComponent();
        store.state.state = STATUS_CLOSED;

        await nextTick();
        expect(findToggleStatusButton().classes()).toContain('btn-open');
      });
    });

    describe('actionButtonText', () => {
      it('returns string `Close epic` when `isEpicOpen` is true', () => {
        createComponent();
        store.state.state = STATUS_OPEN;

        expect(findToggleStatusButton().text()).toBe('Close epic');
      });

      it('returns string `Reopen epic` when `isEpicOpen` is false', async () => {
        createComponent();
        store.state.state = STATUS_CLOSED;

        await nextTick();
        expect(findToggleStatusButton().text()).toBe('Reopen epic');
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `detail-page-header`', () => {
      createComponent();
      expect(wrapper.classes()).toContain('detail-page-header');
      expect(wrapper.find('.detail-page-header-body').exists()).toBe(true);
    });

    it('renders epic status icon and text elements', () => {
      createComponent();
      const statusBox = findStatusBox();

      expect(statusBox.exists()).toBe(true);
      expect(statusBox.findComponent(GlIcon).props('name')).toBe('epic');
      expect(statusBox.find('span').text()).toBe('Open');
    });

    it('renders confidential icon when `confidential` prop is true', async () => {
      createComponent();
      store.state.confidential = true;

      await nextTick();
      const confidentialIcon = findConfidentialIcon();

      expect(confidentialIcon.exists()).toBe(true);
      expect(confidentialIcon.props()).toMatchObject({
        workspaceType: 'project',
        issuableType: 'issue',
      });
    });

    it('renders epic author details element', () => {
      createComponent();
      const epicDetails = findAuthorDetails();

      expect(epicDetails.exists()).toBe(true);
      expect(epicDetails.findComponent(TimeagoTooltip).exists()).toBe(true);
      expect(epicDetails.findComponent(UserAvatarLink).exists()).toBe(true);
    });

    it('renders action buttons element', () => {
      createComponent();
      const actionButtons = findActionButtons();
      const toggleStatusButton = findToggleStatusButton();

      expect(actionButtons.exists()).toBe(true);
      expect(toggleStatusButton.exists()).toBe(true);
      expect(toggleStatusButton.text()).toBe('Close epic');
    });

    it('renders toggle sidebar button element', () => {
      createComponent();
      const toggleButton = findSidebarToggle();

      expect(toggleButton.exists()).toBe(true);
      expect(toggleButton.attributes('aria-label')).toBe('Toggle sidebar');
      expect(toggleButton.classes()).toEqual(
        expect.arrayContaining(['gl-display-block', 'd-sm-none', 'gutter-toggle']),
      );
    });

    it('renders GitLab team member badge when `author.isGitlabEmployee` is `true`', async () => {
      createComponent();
      store.state.author.isGitlabEmployee = true;

      // Wait for dynamic imports to resolve
      await waitForPromises();
      expect(wrapper.vm.$refs.gitlabTeamMemberBadge).not.toBeUndefined();
    });

    it('does not render new epic button if user cannot create it', async () => {
      createComponent();
      store.state.canCreate = false;

      await nextTick();
      expect(findNewEpicButton().exists()).toBe(false);
    });

    it('renders new epic button if user can create it', async () => {
      createComponent();
      store.state.canCreate = true;

      await nextTick();
      expect(findNewEpicButton().exists()).toBe(true);
    });

    it('does not render delete epic button if user cannot create it', async () => {
      createComponent();
      store.state.canDestroy = false;

      await nextTick();
      expect(findDeleteEpicButton().exists()).toBe(false);
    });

    it('renders delete epic button if user can create it', async () => {
      createComponent();
      store.state.canDestroy = true;

      await nextTick();
      expect(findDeleteEpicButton().exists()).toBe(true);
    });

    describe('delete issue modal', () => {
      it('renders', () => {
        createComponent();
        expect(findModal().props()).toEqual({
          issuePath: '',
          issueType: 'epic',
          modalId,
          title: 'Delete epic',
        });
      });
    });
  });

  describe('edit button', () => {
    it('shows the edit button', () => {
      createComponent();
      expect(findEditButton().exists()).toBe(true);
    });

    it('should trigger "open.form" event when clicked', async () => {
      createComponent();
      expect(issuesEventHub.$emit).not.toHaveBeenCalled();
      await findEditButton().trigger('click');
      expect(issuesEventHub.$emit).toHaveBeenCalledWith('open.form');
    });
  });

  describe('moved_mr_sidebar flag FF', () => {
    describe('when the flag is off', () => {
      beforeEach(() => {
        createComponent({ isMoveSidebarEnabled: false });
      });

      it('does not render Notification toggle', () => {
        expect(findNotificationWidget().exists()).toBe(false);
      });

      it('does not render the copy reference toggle', () => {
        expect(findCopyRefenceDropdownItem().exists()).toBe(false);
      });
    });

    describe('when the flag is on', () => {
      beforeEach(() => {
        createComponent({ isMoveSidebarEnabled: true });
      });

      it('renders the Notification toggle', () => {
        expect(findNotificationWidget().exists()).toBe(true);
      });

      it('does not render the copy reference toggle', () => {
        expect(findCopyRefenceDropdownItem().exists()).toBe(true);
      });
    });
  });
});
