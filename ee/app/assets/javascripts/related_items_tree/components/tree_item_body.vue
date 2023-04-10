<script>
import {
  GlButton,
  GlIcon,
  GlLabel,
  GlLink,
  GlModalDirective,
  GlTooltip,
  GlTooltipDirective,
} from '@gitlab/ui';
import { isEmpty, isNumber } from 'lodash';
import { mapState, mapActions } from 'vuex';

import ItemWeight from 'ee/boards/components/issue_card_weight.vue';
import ItemDueDate from '~/boards/components/issue_due_date.vue';
import { __ } from '~/locale';
import { isScopedLabel } from '~/lib/utils/common_utils';

import ItemAssignees from '~/issuable/components/issue_assignees.vue';
import ItemMilestone from '~/issuable/components/issue_milestone.vue';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';

import { ChildType, itemRemoveModalId } from '../constants';
import EpicHealthStatus from './epic_health_status.vue';
import IssueHealthStatus from './issue_health_status.vue';

import StateTooltip from './state_tooltip.vue';

export default {
  itemRemoveModalId,
  components: {
    GlIcon,
    GlLabel,
    GlLink,
    GlTooltip,
    GlButton,
    StateTooltip,
    ItemMilestone,
    ItemAssignees,
    ItemDueDate,
    ItemWeight,
    EpicHealthStatus,
    IssueHealthStatus,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  props: {
    parentItem: {
      type: Object,
      required: true,
    },
    labelsFilterParam: {
      type: String,
      required: false,
      default: 'label_name',
    },
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState([
      'allowIssuableHealthStatus',
      'allowScopedLabels',
      'allowSubEpics',
      'childrenFlags',
      'epicsWebUrl',
      'isShowingLabels',
      'issuesWebUrl',
      'userSignedIn',
    ]),
    itemReference() {
      return this.item.reference;
    },
    itemWebPath() {
      // Here, GraphQL API (during item fetch) returns `webPath`
      // and Rails API (during item add) returns `path`,
      // we need to make both accessible.
      return this.item.path || this.item.webPath;
    },
    isOpen() {
      return this.item.state === STATUS_OPEN;
    },
    isBlocked() {
      return this.item.blocked;
    },
    isClosed() {
      return this.item.state === STATUS_CLOSED;
    },
    hasMilestone() {
      return !isEmpty(this.item.milestone);
    },
    hasAssignees() {
      return this.item.assignees && this.item.assignees.length > 0;
    },
    hasWeight() {
      return isNumber(this.item.weight);
    },
    showLabels() {
      return this.isShowingLabels && this.item.labels?.length > 0;
    },
    stateText() {
      return this.isOpen ? __('Created') : __('Closed');
    },
    stateIconName() {
      if (this.item.type === ChildType.Epic) {
        return this.isOpen ? 'epic' : 'epic-closed';
      }
      if (this.isBlocked && this.isOpen) {
        return 'issue-block';
      }
      return this.isOpen ? 'issues' : 'issue-closed';
    },
    stateIconClass() {
      if (this.isBlocked && this.isOpen) {
        return 'gl-text-red-500';
      }
      return this.isOpen
        ? 'issue-token-state-icon-open gl-text-green-500'
        : 'issue-token-state-icon-closed gl-text-blue-500';
    },
    itemId() {
      return this.itemReference.split(this.item.pathIdSeparator).pop();
    },
    itemPath() {
      return this.itemReference.split(this.item.pathIdSeparator)[0];
    },
    itemHierarchy() {
      return this.itemPath + this.item.pathIdSeparator + this.itemId;
    },
    computedPath() {
      return this.itemWebPath.length ? this.itemWebPath : null;
    },
    canAdminRelation() {
      return this.parentItem.userPermissions.canAdminRelation;
    },
    itemActionInProgress() {
      return (
        this.childrenFlags[this.itemReference].itemChildrenFetchInProgress ||
        this.childrenFlags[this.itemReference].itemRemoveInProgress
      );
    },
    showEmptySpacer() {
      return !this.canAdminRelation && this.userSignedIn;
    },
    totalEpicsCount() {
      const { descendantCounts: { openedEpics = 0, closedEpics = 0 } = {} } = this.item;

      return openedEpics + closedEpics;
    },
    totalIssuesCount() {
      const { descendantCounts: { openedIssues = 0, closedIssues = 0 } = {} } = this.item;

      return openedIssues + closedIssues;
    },
    isEpic() {
      return this.item.type === ChildType.Epic;
    },
    isIssue() {
      return this.item.type === ChildType.Issue;
    },
    showHealthStatus() {
      return this.item.healthStatus && this.allowIssuableHealthStatus;
    },
    showIssueHealthStatus() {
      return this.isIssue && this.isOpen && this.showHealthStatus;
    },
    showEpicHealthStatus() {
      const { descendantCounts: { openedIssues = 0 } = {} } = this.item;
      return this.isEpic && this.showHealthStatus && openedIssues > 0;
    },
  },
  methods: {
    ...mapActions(['setRemoveItemModalProps']),
    handleRemoveClick() {
      const { parentItem, item } = this;

      this.setRemoveItemModalProps({
        parentItem,
        item,
      });
    },
    showScopedLabel(label) {
      return isScopedLabel(label) && this.allowScopedLabels;
    },
    labelFilterUrl(label) {
      let basePath = this.issuesWebUrl;

      if (this.isEpic) {
        basePath = this.epicsWebUrl;
      }

      return `${basePath}?${this.labelsFilterParam}[]=${encodeURIComponent(label.title)}`;
    },
  },
};
</script>

<template>
  <div class="sortable-row gl-flex-grow-1">
    <div
      class="item-body gl-display-flex gl-align-items-center gl-pl-3 gl-pr-2 gl-py-2 gl-mx-n2"
      :class="{
        'item-logged-out': !userSignedIn,
        'item-closed': isClosed,
      }"
    >
      <div class="gl-display-flex gl-align-items-center gl-flex-nowrap gl-flex-grow-1">
        <div class="item-title-wrapper gl-flex-grow-1 gl-mr-3">
          <div class="item-title gl-display-flex gl-mb-0 gl-py-1">
            <gl-icon
              ref="stateIconMd"
              class="gl-display-block gl-mr-3"
              :class="stateIconClass"
              :name="stateIconName"
              :aria-label="stateText"
            />
            <state-tooltip
              :get-target-ref="() => $refs.stateIconMd"
              :path="itemHierarchy"
              :is-open="isOpen"
              :state="item.state"
              :created-at="item.createdAt"
              :closed-at="item.closedAt || ''"
            />
            <gl-icon
              v-if="item.confidential"
              v-gl-tooltip.hover
              :title="__('Confidential')"
              :aria-label="__('Confidential')"
              name="eye-slash"
              class="confidential-icon gl-mr-2 align-self-baseline align-self-md-auto mt-xl-0"
            />
            <gl-link
              v-gl-tooltip.hover
              :aria-label="item.title"
              :title="item.title"
              :href="computedPath"
              class="sortable-link ws-normal gl-font-weight-bold"
              >{{ item.title }}</gl-link
            >
          </div>

          <div
            class="item-meta gl-display-flex gl-flex-wrap mt-xl-0 gl-align-items-center gl-font-sm gl-ml-6"
          >
            <span class="gl-mr-4 gl-mb-1">{{ itemHierarchy }}</span>
            <gl-tooltip v-if="isEpic" :target="() => $refs.countBadge">
              <p v-if="allowSubEpics" class="gl-font-weight-bold gl-m-0">
                {{ __('Epics') }} &#8226;
                <span class="gl-text-gray-400 gl-font-weight-normal"
                  >{{
                    sprintf(__('%{openedEpics} open, %{closedEpics} closed'), {
                      openedEpics: item.descendantCounts && item.descendantCounts.openedEpics,
                      closedEpics: item.descendantCounts && item.descendantCounts.closedEpics,
                    })
                  }}
                </span>
              </p>
              <p class="gl-font-weight-bold gl-m-0">
                {{ __('Issues') }} &#8226;
                <span class="gl-text-gray-400 gl-font-weight-normal"
                  >{{
                    sprintf(__('%{openedIssues} open, %{closedIssues} closed'), {
                      openedIssues: item.descendantCounts && item.descendantCounts.openedIssues,
                      closedIssues: item.descendantCounts && item.descendantCounts.closedIssues,
                    })
                  }}
                </span>
              </p>
            </gl-tooltip>

            <div
              v-if="isEpic"
              ref="countBadge"
              class="gl-text-gray-500 gl-display-inline-flex gl-py-0 p-lg-0"
            >
              <span
                v-if="allowSubEpics"
                class="gl-display-inline-flex gl-align-items-center gl-mr-4 gl-mb-1"
              >
                <gl-icon name="epic" class="gl-mr-2" />
                {{ totalEpicsCount }}
              </span>
              <span class="gl-display-inline-flex gl-align-items-center gl-mr-4 gl-mb-1">
                <gl-icon name="issues" class="gl-mr-2" />
                {{ totalIssuesCount }}
              </span>
            </div>

            <item-milestone
              v-if="hasMilestone"
              :milestone="item.milestone"
              class="item-milestone gl-display-flex gl-align-items-center gl-mr-4 gl-mb-1"
            />

            <item-due-date
              v-if="item.dueDate"
              :date="item.dueDate"
              :closed="Boolean(item.closedAt)"
              tooltip-placement="top"
              css-class="item-due-date gl-display-flex gl-align-items-center gl-mr-4! gl-mb-1"
            />

            <item-weight
              v-if="hasWeight"
              :weight="item.weight"
              class="item-weight gl-display-flex gl-align-items-center gl-mr-4! gl-mb-1"
              tag-name="span"
            />

            <item-assignees
              v-if="hasAssignees"
              :assignees="item.assignees"
              class="item-assignees gl-display-inline-flex gl-align-items-center gl-mr-4 gl-mb-1 flex-xl-grow-0"
            />

            <epic-health-status
              v-if="showEpicHealthStatus"
              :health-status="item.healthStatus"
              data-testid="epic-health-status"
              class="gl-mr-4 gl-mb-1"
            />
            <issue-health-status
              v-if="showIssueHealthStatus"
              :health-status="item.healthStatus"
              data-testid="issue-health-status"
              class="gl-mr-4 gl-mb-1"
            />

            <template v-if="showLabels">
              <gl-label
                v-for="label in item.labels"
                :key="label.id"
                :background-color="label.color"
                :description="label.description"
                :scoped="showScopedLabel(label)"
                :target="labelFilterUrl(label)"
                :title="label.title"
                class="gl-mr-2 gl-mb-1 gl-label-sm"
                tooltip-placement="top"
              />
            </template>
          </div>
        </div>

        <gl-button
          v-if="canAdminRelation"
          v-gl-tooltip.hover
          v-gl-modal-directive="$options.itemRemoveModalId"
          category="tertiary"
          size="small"
          :title="__('Remove')"
          :aria-label="__('Remove')"
          :disabled="itemActionInProgress"
          icon="close"
          class="js-issue-item-remove-button gl-align-self-start"
          data-qa-selector="remove_issue_button"
          @click="handleRemoveClick"
        />
        <span v-if="showEmptySpacer" class="gl-p-3"></span>
      </div>
    </div>
  </div>
</template>
