<script>
import { GlLoadingIcon, GlLink, GlTooltip, GlIcon } from '@gitlab/ui';
import { escape } from 'lodash';
import { STATUS_OPEN } from '~/issues/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';

import { __ } from '~/locale';

export default {
  name: 'AncestorsTree',
  components: {
    GlIcon,
    GlLoadingIcon,
    GlLink,
    GlTooltip,
  },
  directives: {
    SafeHtml,
  },
  props: {
    ancestors: {
      type: Array,
      required: true,
      default: () => [],
    },
    isFetching: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    tooltipText() {
      /**
       * Since the list is reversed, our immediate parent is
       * the last element of the list
       */
      const immediateParent = this.ancestors.slice(-1)[0];

      if (!immediateParent) {
        return __('None');
      }
      // Fallback to None if immediate parent is unavailable.

      let { title } = immediateParent;
      title = escape(title);

      const { humanReadableEndDate, humanReadableTimestamp } = immediateParent;

      if (humanReadableEndDate || humanReadableTimestamp) {
        title += '<br />';
        title += humanReadableEndDate ? `${humanReadableEndDate} ` : '';
        title += humanReadableTimestamp ? `(${humanReadableTimestamp})` : '';
      }

      return title;
    },
  },
  methods: {
    getIcon(ancestor) {
      return ancestor.state === STATUS_OPEN ? 'issue-open-m' : 'issue-close';
    },
    getTimelineClass(ancestor) {
      return ancestor.state === STATUS_OPEN ? 'opened' : 'closed';
    },
  },
};
</script>

<template>
  <div class="ancestor-tree gl-reset-bg">
    <div ref="sidebarIcon" class="sidebar-collapsed-icon">
      <div><gl-icon name="epic" /></div>
      <span v-if="!isFetching" class="collapse-truncated-title gl-pt-2 gl-px-3 gl-font-sm">{{
        tooltipText
      }}</span>
    </div>

    <gl-tooltip :target="() => $refs.sidebarIcon" placement="left" boundary="viewport">
      <span v-safe-html="tooltipText"></span>
    </gl-tooltip>
    <div class="title hide-collapsed gl-mb-2 gl-font-weight-bold">{{ __('Ancestors') }}</div>

    <ul v-if="!isFetching && ancestors.length" class="vertical-timeline hide-collapsed gl-reset-bg">
      <template v-for="(ancestor, index) in ancestors">
        <li
          v-if="ancestor.hasParent && index === 0"
          :key="`${ancestor.id}-has-parent`"
          class="vertical-timeline-row gl-display-flex gl-reset-bg"
          data-testid="ancestor-parent-warning"
        >
          <div class="vertical-timeline-icon gl-text-orange-500 gl-reset-bg">
            <gl-icon name="warning" />
          </div>
          <div class="vertical-timeline-content">
            <span class="gl-text-gray-900">{{
              __("You don't have permission to view this epic")
            }}</span>
          </div>
        </li>
        <li :key="ancestor.id" class="vertical-timeline-row gl-display-flex gl-reset-bg">
          <div class="vertical-timeline-icon gl-reset-bg" :class="getTimelineClass(ancestor)">
            <gl-icon :name="getIcon(ancestor)" />
          </div>
          <div class="vertical-timeline-content">
            <gl-link :href="ancestor.url" class="gl-text-gray-900">{{ ancestor.title }}</gl-link>
          </div>
        </li>
      </template>
    </ul>

    <div v-if="!isFetching && !ancestors.length" class="value hide-collapsed">
      <span class="no-value">{{ __('None') }}</span>
    </div>

    <gl-loading-icon v-if="isFetching" size="sm" />
  </div>
</template>
