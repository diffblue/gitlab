import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import EpicHeader from 'ee/epic/components/epic_header.vue';
import { statusType } from 'ee/epic/constants';
import createStore from 'ee/epic/store';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('EpicHeaderComponent', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    wrapper = shallowMount(EpicHeader, {
      store,
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findStatusBox = () => wrapper.find('[data-testid="status-box"]');
  const findStatusIcon = () => wrapper.find('[data-testid="status-icon"]');
  const findStatusText = () => wrapper.find('[data-testid="status-text"]');
  const findConfidentialIcon = () =>
    wrapper.find('[data-testid="confidential-icon"]').findComponent(GlIcon);
  const findAuthorDetails = () => wrapper.find('[data-testid="author-details"]');
  const findActionButtons = () => wrapper.find('[data-testid="action-buttons"]');
  const findToggleStatusButton = () => wrapper.find('[data-testid="toggle-status-button"]');
  const findNewEpicButton = () => wrapper.find('[data-testid="new-epic-button"]');
  const findSidebarToggle = () => wrapper.find('[data-testid="sidebar-toggle"]');

  describe('computed', () => {
    describe('statusIcon', () => {
      it('returns string `issue-open-m` when `isEpicOpen` is true', () => {
        store.state.state = statusType.open;

        expect(findStatusIcon().props('name')).toBe('issue-open-m');
      });

      it('returns string `mobile-issue-close` when `isEpicOpen` is false', () => {
        store.state.state = statusType.close;

        return wrapper.vm.$nextTick().then(() => {
          expect(findStatusIcon().props('name')).toBe('mobile-issue-close');
        });
      });
    });

    describe('statusText', () => {
      it('returns string `Open` when `isEpicOpen` is true', () => {
        store.state.state = statusType.open;

        expect(findStatusText().text()).toBe('Open');
      });

      it('returns string `Closed` when `isEpicOpen` is false', () => {
        store.state.state = statusType.close;

        return wrapper.vm.$nextTick().then(() => {
          expect(findStatusText().text()).toBe('Closed');
        });
      });
    });

    describe('actionButtonClass', () => {
      it('returns `btn-close` when `isEpicOpen` is true', () => {
        store.state.state = statusType.open;

        expect(findToggleStatusButton().classes()).toContain('btn-close');
      });

      it('returns `btn-open` when `isEpicOpen` is false', () => {
        store.state.state = statusType.close;

        return wrapper.vm.$nextTick().then(() => {
          expect(findToggleStatusButton().classes()).toContain('btn-open');
        });
      });
    });

    describe('actionButtonText', () => {
      it('returns string `Close epic` when `isEpicOpen` is true', () => {
        store.state.state = statusType.open;

        expect(findToggleStatusButton().text()).toBe('Close epic');
      });

      it('returns string `Reopen epic` when `isEpicOpen` is false', () => {
        store.state.state = statusType.close;

        return wrapper.vm.$nextTick().then(() => {
          expect(findToggleStatusButton().text()).toBe('Reopen epic');
        });
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `detail-page-header`', () => {
      expect(wrapper.classes()).toContain('detail-page-header');
      expect(wrapper.find('.detail-page-header-body').exists()).toBeTruthy();
    });

    it('renders epic status icon and text elements', () => {
      const statusBox = findStatusBox();

      expect(statusBox.exists()).toBe(true);
      expect(statusBox.findComponent(GlIcon).props('name')).toBe('issue-open-m');
      expect(statusBox.find('span').text()).toBe('Open');
    });

    it('renders confidential icon when `confidential` prop is true', () => {
      store.state.confidential = true;

      return wrapper.vm.$nextTick(() => {
        const confidentialIcon = findConfidentialIcon();

        expect(confidentialIcon.exists()).toBe(true);
        expect(confidentialIcon.props('name')).toBe('eye-slash');
      });
    });

    it('renders epic author details element', () => {
      const epicDetails = findAuthorDetails();

      expect(epicDetails.exists()).toBe(true);
      expect(epicDetails.findComponent(TimeagoTooltip).exists()).toBe(true);
      expect(epicDetails.findComponent(UserAvatarLink).exists()).toBe(true);
    });

    it('renders action buttons element', () => {
      const actionButtons = findActionButtons();
      const toggleStatusButton = findToggleStatusButton();

      expect(actionButtons.exists()).toBeTruthy();
      expect(toggleStatusButton.exists()).toBeTruthy();
      expect(toggleStatusButton.text()).toBe('Close epic');
    });

    it('renders toggle sidebar button element', () => {
      const toggleButton = findSidebarToggle();

      expect(toggleButton.exists()).toBeTruthy();
      expect(toggleButton.attributes('aria-label')).toBe('Toggle sidebar');
      expect(toggleButton.classes()).toEqual(
        expect.arrayContaining(['gl-display-block', 'd-sm-none', 'gutter-toggle']),
      );
    });

    it('renders GitLab team member badge when `author.isGitlabEmployee` is `true`', () => {
      store.state.author.isGitlabEmployee = true;

      // Wait for dynamic imports to resolve
      return new Promise(setImmediate).then(() => {
        expect(wrapper.vm.$refs.gitlabTeamMemberBadge).not.toBeUndefined();
      });
    });

    it('does not render new epic button if user cannot create it', () => {
      store.state.canCreate = false;

      return wrapper.vm.$nextTick().then(() => {
        expect(findNewEpicButton().exists()).toBe(false);
      });
    });

    it('renders new epic button if user can create it', () => {
      store.state.canCreate = true;

      return wrapper.vm.$nextTick().then(() => {
        expect(findNewEpicButton().exists()).toBe(true);
      });
    });
  });
});
