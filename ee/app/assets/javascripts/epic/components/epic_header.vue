<script>
import {
  GlButton,
  GlBadge,
  GlIcon,
  GlTooltipDirective,
  GlModalDirective,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
} from '@gitlab/ui';
import { mapState, mapGetters, mapActions } from 'vuex';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';

import { __ } from '~/locale';

import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import DeleteIssueModal from '~/issues/show/components/delete_issue_modal.vue';

import { IssuableType, WorkspaceType } from '~/issues/constants';
import { statusType } from '../constants';
import epicUtils from '../utils/epic_utils';

export default {
  WorkspaceType,
  IssuableType,
  deleteModalId: 'delete-modal-id',
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  components: {
    DeleteIssueModal,
    GlIcon,
    GlBadge,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    UserAvatarLink,
    TimeagoTooltip,
    ConfidentialityBadge,
    GitlabTeamMemberBadge: () =>
      import('ee_component/vue_shared/components/user_avatar/badges/gitlab_team_member_badge.vue'),
  },
  i18n: {
    deleteButtonText: __('Delete epic'),
    dropdownText: __('Epic actions'),
    newEpicText: __('New epic'),
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
      'canDestroy',
      'confidential',
      'newEpicWebUrl',
    ]),
    ...mapGetters(['isEpicOpen']),
    statusIcon() {
      return this.isEpicOpen ? 'epic' : 'epic-closed';
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
      <gl-badge
        class="issuable-status-badge gl-mr-3"
        :variant="isEpicOpen ? 'success' : 'info'"
        data-testid="status-box"
      >
        <gl-icon :name="statusIcon" data-testid="status-icon" />
        <span class="gl-display-none gl-sm-display-block gl-ml-2" data-testid="status-text">{{
          statusText
        }}</span>
      </gl-badge>
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
      <gl-dropdown
        v-if="canUpdate || canCreate || canDestroy"
        class="gl-sm-display-none! gl-mt-3 w-100"
        block
        :text="$options.i18n.dropdownText"
        data-testid="mobile-dropdown"
      >
        <gl-dropdown-item v-if="canCreate" :href="newEpicWebUrl">
          {{ $options.i18n.newEpicText }}
        </gl-dropdown-item>
        <gl-dropdown-item v-if="canUpdate" @click="toggleEpicStatus(isEpicOpen)">
          {{ actionButtonText }}
        </gl-dropdown-item>
        <template v-if="canDestroy">
          <gl-dropdown-divider />
          <gl-dropdown-item
            v-gl-modal="$options.deleteModalId"
            variant="danger"
            data-testid="delete-epic-button"
          >
            {{ $options.i18n.deleteButtonText }}
          </gl-dropdown-item>
        </template>
      </gl-dropdown>

      <gl-button
        v-if="canUpdate"
        :loading="epicStatusChangeInProgress"
        :class="actionButtonClass"
        category="secondary"
        variant="default"
        class="gl-display-none gl-sm-display-inline-flex! gl-mt-3 gl-sm-mt-0! gl-w-full gl-sm-w-auto!"
        data-qa-selector="close_reopen_epic_button"
        data-testid="toggle-status-button"
        @click="toggleEpicStatus(isEpicOpen)"
      >
        {{ actionButtonText }}
      </gl-button>

      <gl-dropdown
        v-if="canCreate || canDestroy"
        v-gl-tooltip.hover
        class="gl-display-none gl-sm-display-inline-flex! gl-ml-3"
        icon="ellipsis_v"
        category="tertiary"
        :text="$options.i18n.dropdownText"
        :text-sr-only="true"
        :title="$options.i18n.dropdownText"
        :aria-label="$options.i18n.dropdownText"
        no-caret
        right
        data-testid="desktop-dropdown"
      >
        <gl-dropdown-item v-if="canCreate" :href="newEpicWebUrl" data-testid="new-epic-button">
          {{ $options.i18n.newEpicText }}
        </gl-dropdown-item>
        <template v-if="canDestroy">
          <gl-dropdown-divider />
          <gl-dropdown-item
            v-gl-modal="$options.deleteModalId"
            variant="danger"
            data-testid="delete-epic-button"
          >
            {{ $options.i18n.deleteButtonText }}
          </gl-dropdown-item>
        </template>
      </gl-dropdown>
    </div>
    <delete-issue-modal
      :issue-type="$options.IssuableType.Epic"
      :modal-id="$options.deleteModalId"
      :title="$options.i18n.deleteButtonText"
    />
  </div>
</template>
