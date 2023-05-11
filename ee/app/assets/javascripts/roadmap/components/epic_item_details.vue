<script>
import { GlButton, GlIcon, GlLabel, GlTooltip } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { getIdFromGraphQLId, getNodesOrDefault } from '~/graphql_shared/utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { queryToObject, updateHistory } from '~/lib/utils/url_utility';
import { __, n__ } from '~/locale';
import IssuableBlockedIcon from '~/vue_shared/components/issuable_blocked_icon/issuable_blocked_icon.vue';
import { EPIC_LEVEL_MARGIN, UNSUPPORTED_ROADMAP_PARAMS } from '../constants';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLabel,
    GlTooltip,
    IssuableBlockedIcon,
  },
  props: {
    epic: {
      type: Object,
      required: true,
    },
    currentGroupId: {
      type: Number,
      required: true,
    },
    timeframeString: {
      type: String,
      required: true,
    },
    childLevel: {
      type: Number,
      required: true,
    },
    childrenFlags: {
      type: Object,
      required: true,
    },
    hasFiltersApplied: {
      type: Boolean,
      required: true,
    },
    isChildrenEmpty: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['allowSubEpics', 'isShowingLabels', 'filterParams']),
    itemId() {
      return this.epic.id;
    },
    epicGroupId() {
      return getIdFromGraphQLId(this.epic.group.id);
    },
    isEpicGroupDifferent() {
      return this.currentGroupId !== this.epicGroupId;
    },
    isExpandIconHidden() {
      return !this.epic.hasChildren;
    },
    isEmptyChildrenWithFilter() {
      return (
        this.childrenFlags[this.itemId].itemExpanded &&
        this.hasFiltersApplied &&
        this.isChildrenEmpty
      );
    },
    expandIconName() {
      if (this.isEmptyChildrenWithFilter) {
        return 'information-o';
      }
      return this.childrenFlags[this.itemId].itemExpanded ? 'chevron-down' : 'chevron-right';
    },
    infoSearchLabel() {
      return __('No child epics match applied filters');
    },
    expandIconLabel() {
      if (this.isEmptyChildrenWithFilter) {
        return this.infoSearchLabel;
      }
      return this.childrenFlags[this.itemId].itemExpanded ? __('Collapse') : __('Expand');
    },
    childrenFetchInProgress() {
      return this.epic.hasChildren && this.childrenFlags[this.itemId].itemChildrenFetchInProgress;
    },
    childEpicsCount() {
      const { openedEpics = 0, closedEpics = 0 } = this.epic.descendantCounts;
      return openedEpics + closedEpics;
    },
    childEpicsCountText() {
      return Number.isInteger(this.childEpicsCount)
        ? n__(`%d child epic`, `%d child epics`, this.childEpicsCount)
        : '';
    },
    childEpicsSearchText() {
      return __('Some child epics may be hidden due to applied filters');
    },
    childMarginClassname() {
      return EPIC_LEVEL_MARGIN[this.childLevel];
    },
    epicLabels() {
      return getNodesOrDefault(this.epic.labels);
    },
    hasLabels() {
      return this.epicLabels.length > 0;
    },
  },
  methods: {
    ...mapActions(['setFilterParams', 'fetchEpics']),
    toggleIsEpicExpanded() {
      if (!this.isEmptyChildrenWithFilter) {
        eventHub.$emit('toggleIsEpicExpanded', this.epic);
      }
    },
    filterByLabelUrl(label) {
      const filterPath = window.location.search ? `${window.location.search}&` : '?';
      const filter = `label_name[]=${encodeURIComponent(label.title)}`;
      return `${filterPath}${filter}`;
    },
    filterByLabel(label) {
      const alreadySelected = this.filterParams?.labelName?.includes(label.title);

      if (!alreadySelected) {
        updateHistory({
          url: this.filterByLabelUrl(label),
        });
        this.setFilterParams(
          convertObjectPropsToCamelCase(
            queryToObject(window.location.search, { gatherArrays: true }),
            { dropKeys: UNSUPPORTED_ROADMAP_PARAMS },
          ),
        );
        this.fetchEpics();
      }
    },
  },
};
</script>

<template>
  <div
    class="epic-details-cell gl-display-flex gl-flex-direction-column gl-justify-content-center"
    data-qa-selector="epic_details_cell"
  >
    <div
      class="gl-display-flex align-items-start gl-p-3"
      :class="[epic.isChildEpic ? childMarginClassname : '']"
      data-testid="epic-container"
    >
      <span ref="expandCollapseInfo">
        <gl-button
          v-if="!childrenFetchInProgress"
          :class="{ invisible: isExpandIconHidden }"
          :aria-label="expandIconLabel"
          category="tertiary"
          size="small"
          :icon="expandIconName"
          :loading="childrenFetchInProgress"
          data-testid="expand-icon-button"
          @click="toggleIsEpicExpanded"
        />
      </span>
      <gl-tooltip
        v-if="!isExpandIconHidden"
        ref="expandIconTooltip"
        triggers="hover"
        :target="() => $refs.expandCollapseInfo"
        boundary="viewport"
        offset="15"
        placement="topright"
        data-testid="expand-icon-tooltip"
      >
        {{ expandIconLabel }}
      </gl-tooltip>
      <div class="flex-grow-1 mx-1 gl-w-13">
        <div class="gl-display-flex gl-mt-1">
          <issuable-blocked-icon
            v-if="epic.blocked"
            :item="epic"
            :unique-id="epic.id"
            issuable-type="epic"
            data-testid="blocked-icon"
          />
          <a
            :href="epic.webUrl"
            :title="epic.title"
            class="epic-title text-body gl-font-weight-bold"
            data-testid="epic-title"
          >
            {{ epic.title }}
          </a>
        </div>
        <div class="epic-group-timeframe gl-display-flex text-secondary">
          <span
            v-if="isEpicGroupDifferent && !epic.hasParent"
            :title="epic.group.fullName"
            class="epic-group"
            data-testid="epic-group"
          >
            {{ epic.group.name }}
          </span>
          <span v-if="isEpicGroupDifferent && !epic.hasParent" class="mx-1" aria-hidden="true"
            >&middot;</span
          >
          <span class="epic-timeframe" :title="timeframeString">{{ timeframeString }}</span>
        </div>
        <div v-if="hasLabels && isShowingLabels" data-testid="epic-labels" class="gl-mt-2">
          <gl-label
            v-for="label in epicLabels"
            :key="label.id"
            class="js-no-trigger gl-mt-2 gl-mr-2"
            :background-color="label.color"
            :title="label.title"
            size="sm"
            :target="filterByLabelUrl(label)"
            @click.prevent="filterByLabel(label)"
          />
        </div>
      </div>
      <template v-if="allowSubEpics">
        <div
          ref="childEpicsCount"
          class="gl-mt-1 gl-display-flex text-secondary text-nowrap"
          data-testid="child-epics-count"
        >
          <gl-icon name="epic" class="align-text-bottom mr-1" />
          <p class="m-0" :aria-label="childEpicsCountText">{{ childEpicsCount }}</p>
        </div>
        <gl-tooltip
          ref="childEpicsCountTooltip"
          :target="() => $refs.childEpicsCount"
          data-testid="child-epics-count-tooltip"
        >
          <span :class="{ bold: hasFiltersApplied }">{{ childEpicsCountText }}</span>
          <span v-if="hasFiltersApplied" class="d-block">{{ childEpicsSearchText }}</span>
        </gl-tooltip>
      </template>
    </div>
  </div>
</template>
