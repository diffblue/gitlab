<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { mapState, mapGetters, mapActions } from 'vuex';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';

import { __ } from '~/locale';

import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';

import { IssuableType, WorkspaceType } from '~/issues/constants';
import { statusType } from '../constants';
import epicUtils from '../utils/epic_utils';

export default {
  WorkspaceType,
  IssuableType,
  directives: {
    GlTooltipDirective,
  },
  components: {
    GlIcon,
    GlButton,
    UserAvatarLink,
    TimeagoTooltip,
    ConfidentialityBadge,
    GitlabTeamMemberBadge: () =>
      import('ee_component/vue_shared/components/user_avatar/badges/gitlab_team_member_badge.vue'),
  },
  computed: {
    ...mapState([
      'sidebarCollapsed',
      'epicDeleteInProgress',
      'epicStatusChangeInProgress',
      'author',
      'created',
      'canCreate',
      'canUpdate',
      'confidential',
      'newEpicWebUrl',
    ]),
    ...mapGetters(['isEpicOpen']),
    statusIcon() {
      return this.isEpicOpen ? 'issue-open-m' : 'mobile-issue-close';
    },
    statusText() {
      return this.isEpicOpen ? __('Open') : __('Closed');
    },
    actionButtonClass() {
      return this.isEpicOpen ? 'btn-close' : 'btn-open';
    },
    actionButtonText() {
      return this.isEpicOpen ? __('Close epic') : __('Reopen epic');
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
        state: isEpicOpen ? statusType.open : statusType.close,
      });
    });
  },
  methods: {
    ...mapActions(['toggleSidebar', 'requestEpicStatusChangeSuccess', 'toggleEpicStatus']),
  },
};
</script>

<template>
  <div class="detail-page-header gl-flex-wrap gl-py-3">
    <div class="detail-page-header-body">
      <div
        :class="{ 'status-box-open': isEpicOpen, 'status-box-issue-closed': !isEpicOpen }"
        class="issuable-status-box status-box"
        data-testid="status-box"
      >
        <gl-icon :name="statusIcon" class="d-block d-sm-none" data-testid="status-icon" />
        <span class="d-none d-sm-block" data-testid="status-text">{{ statusText }}</span>
      </div>
      <div class="issuable-meta" data-testid="author-details">
        <confidentiality-badge
          v-if="confidential"
          data-testid="confidential-icon"
          :workspace-type="$options.WorkspaceType.project"
          :issuable-type="$options.IssuableType.Issue"
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
          <gitlab-team-member-badge
            v-if="author && author.isGitlabEmployee"
            ref="gitlabTeamMemberBadge"
          />
        </strong>
      </div>
    </div>
    <gl-button
      :aria-label="__('Toggle sidebar')"
      type="button"
      class="float-right gl-display-block d-sm-none gl-align-self-center gutter-toggle issuable-gutter-toggle"
      data-testid="sidebar-toggle"
      icon="chevron-double-lg-left"
      @click="toggleSidebar({ sidebarCollapsed })"
    />
    <div
      class="detail-page-header-actions gl-display-flex gl-flex-wrap gl-align-items-center gl-w-full gl-sm-w-auto!"
      data-testid="action-buttons"
    >
      <gl-button
        v-if="canUpdate"
        :loading="epicStatusChangeInProgress"
        :class="actionButtonClass"
        category="secondary"
        variant="default"
        class="gl-mt-3 gl-sm-mt-0! gl-w-full gl-sm-w-auto!"
        data-qa-selector="close_reopen_epic_button"
        data-testid="toggle-status-button"
        @click="toggleEpicStatus(isEpicOpen)"
      >
        {{ actionButtonText }}
      </gl-button>
      <gl-button
        v-if="canCreate"
        :href="newEpicWebUrl"
        category="secondary"
        variant="confirm"
        class="gl-mt-3 gl-sm-mt-0! gl-sm-ml-3 gl-w-full gl-sm-w-auto!"
        data-testid="new-epic-button"
      >
        {{ __('New epic') }}
      </gl-button>
    </div>
  </div>
</template>
