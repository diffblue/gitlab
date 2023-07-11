import { GlBadge, GlButton, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EpicHeader from 'ee/epic/components/epic_header.vue';
import EpicHeaderActions from 'ee/epic/components/epic_header_actions.vue';
import createStore from 'ee/epic/store';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('EpicHeader component', () => {
  let wrapper;

  const createComponent = (state = {}) => {
    const store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', { ...mockEpicData, ...state });

    wrapper = shallowMount(EpicHeader, { store });
  };

  const findConfidentialityBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findEpicHeaderActions = () => wrapper.findComponent(EpicHeaderActions);
  const findStatusBadge = () => wrapper.findComponent(GlBadge);
  const findStatusBadgeIcon = () => wrapper.findComponent(GlIcon);
  const findTimeagoTooltip = () => wrapper.findComponent(TimeagoTooltip);
  const findToggleSidebarButton = () => wrapper.findComponent(GlButton);
  const findUserAvatarLink = () => wrapper.findComponent(UserAvatarLink);

  describe('status badge', () => {
    describe('when epic is open', () => {
      beforeEach(() => {
        createComponent({ state: STATUS_OPEN });
      });

      it('renders `Open` text', () => {
        expect(findStatusBadge().text()).toBe('Open');
      });

      it('renders correct icon', () => {
        expect(findStatusBadgeIcon().props('name')).toBe('epic');
      });
    });

    describe('when epic is closed', () => {
      beforeEach(() => {
        createComponent({ state: STATUS_CLOSED });
      });

      it('renders `Closed` text', () => {
        expect(findStatusBadge().text()).toBe('Closed');
      });

      it('renders correct icon', () => {
        expect(findStatusBadgeIcon().props('name')).toBe('epic-closed');
      });
    });
  });

  it('renders correct badge when epic is confidential', () => {
    createComponent({ confidential: true });

    expect(findConfidentialityBadge().props()).toMatchObject({
      workspaceType: 'group',
      issuableType: 'epic',
    });
  });

  it('renders timeago tooltip', () => {
    createComponent();

    expect(findTimeagoTooltip().exists()).toBe(true);
  });

  it('renders user avatar link', () => {
    createComponent();

    expect(findUserAvatarLink().exists()).toBe(true);
  });

  it('renders toggle sidebar button', () => {
    createComponent();

    expect(findToggleSidebarButton().attributes('aria-label')).toBe('Toggle sidebar');
  });

  it('renders actions dropdown', () => {
    createComponent();

    expect(findEpicHeaderActions().exists()).toBe(true);
  });
});
