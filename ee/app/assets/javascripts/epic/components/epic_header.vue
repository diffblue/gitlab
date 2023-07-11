<script>
import { GlButton, GlBadge, GlIcon } from '@gitlab/ui';
import { mapState, mapGetters, mapActions } from 'vuex';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import { __ } from '~/locale';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import { STATUS_CLOSED, STATUS_OPEN, TYPE_EPIC, WORKSPACE_GROUP } from '~/issues/constants';
import epicUtils from '../utils/epic_utils';
import EpicHeaderActions from './epic_header_actions.vue';

export default {
  TYPE_EPIC,
  WORKSPACE_GROUP,
  components: {
    EpicHeaderActions,
    GlIcon,
    GlBadge,
    GlButton,
    UserAvatarLink,
    TimeagoTooltip,
    ConfidentialityBadge,
  },
  computed: {
    ...mapState(['sidebarCollapsed', 'author', 'created', 'confidential']),
    ...mapGetters(['isEpicOpen']),
    statusIcon() {
      return this.isEpicOpen ? 'epic' : 'epic-closed';
    },
    statusText() {
      return this.isEpicOpen ? __('Open') : __('Closed');
    },
  },
  mounted() {
    /**
     * This event is triggered from Notes app
     * when user clicks on `Close` button below
     * comment form.
     *
     * When event is triggered, we want to reflect Epic status change
     * across the UI so we directly call `requestEpicStatusChangeSuccess` action
     * to update store state.
     */
    epicUtils.bindDocumentEvent(EVENT_ISSUABLE_VUE_APP_CHANGE, (e, isClosed) => {
      const isEpicOpen = e.detail ? !e.detail.isClosed : !isClosed;
      this.requestEpicStatusChangeSuccess({
        state: isEpicOpen ? STATUS_OPEN : STATUS_CLOSED,
      });
    });
  },
  methods: {
    ...mapActions(['toggleSidebar', 'requestEpicStatusChangeSuccess']),
  },
};
</script>

<template>
  <div class="detail-page-header gl-flex-wrap">
    <div class="detail-page-header-body">
      <gl-badge class="issuable-status-badge gl-mr-3" :variant="isEpicOpen ? 'success' : 'info'">
        <gl-icon :name="statusIcon" />
        <span class="gl-display-none gl-sm-display-block gl-ml-2">{{ statusText }}</span>
      </gl-badge>
      <div class="issuable-meta">
        <confidentiality-badge
          v-if="confidential"
          :workspace-type="$options.WORKSPACE_GROUP"
          :issuable-type="$options.TYPE_EPIC"
        />
        {{ __('Created') }}
        <timeago-tooltip :time="created" />
        {{ __('by') }}
        <strong class="text-nowrap">
          <user-avatar-link
            :link-href="author.url"
            :img-src="author.src"
            :img-size="24"
            :tooltip-text="author.username"
            :username="author.name"
            img-css-classes="avatar-inline"
          />
        </strong>
      </div>
    </div>
    <gl-button
      :aria-label="__('Toggle sidebar')"
      type="button"
      class="float-right gl-display-block gl-sm-display-none! gl-align-self-center gutter-toggle issuable-gutter-toggle"
      icon="chevron-double-lg-left"
      @click="toggleSidebar({ sidebarCollapsed })"
    />
    <div
      class="detail-page-header-actions gl-display-flex gl-flex-wrap gl-align-items-center gl-w-full gl-sm-w-auto"
    >
      <epic-header-actions />
    </div>
  </div>
</template>
