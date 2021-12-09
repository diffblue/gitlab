<script>
import { GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { __ } from '~/locale';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { JOB_SIDEBAR } from '../../constants';
import { SIDEBAR_COLLAPSE_BREAKPOINTS } from './constants';

export default {
  name: 'BridgeSidebar',
  i18n: {
    ...JOB_SIDEBAR,
    retryButton: __('Retry'),
    retryTriggerJob: __('Retry the trigger job'),
    retryDownstreamPipeline: __('Retry the downstream pipeline'),
  },
  borderTopClass: ['gl-border-t-solid', 'gl-border-t-1', 'gl-border-t-gray-100'],
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    TooltipOnTruncate,
  },
  inject: {
    buildName: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      isSidebarExpanded: true,
    };
  },
  created() {
    window.addEventListener('resize', this.onResize);
  },
  mounted() {
    this.onResize();
  },
  methods: {
    toggleSidebar() {
      this.isSidebarExpanded = !this.isSidebarExpanded;
    },
    onResize() {
      const breakpoint = bp.getBreakpointSize();
      if (SIDEBAR_COLLAPSE_BREAKPOINTS.includes(breakpoint)) {
        this.isSidebarExpanded = false;
      } else if (!this.isSidebarExpanded) {
        this.isSidebarExpanded = true;
      }
    },
  },
};
</script>
<template>
  <aside
    class="right-sidebar build-sidebar"
    :class="{
      'right-sidebar-expanded': isSidebarExpanded,
      'right-sidebar-collapsed': !isSidebarExpanded,
    }"
    data-offset-top="101"
    data-spy="affix"
  >
    <div class="sidebar-container">
      <div class="blocks-container">
        <div class="gl-py-5 gl-display-flex gl-align-items-center">
          <tooltip-on-truncate :title="buildName" truncate-target="child"
            ><h4 class="gl-mb-0 gl-mr-2 gl-text-truncate">
              {{ buildName }}
            </h4>
          </tooltip-on-truncate>
          <!-- TODO: implement retry actions -->
          <div class="gl-flex-grow-1 gl-flex-shrink-0 gl-text-right">
            <gl-dropdown
              :text="$options.i18n.retryButton"
              category="primary"
              variant="confirm"
              right
              size="medium"
            >
              <gl-dropdown-item>{{ $options.i18n.retryTriggerJob }}</gl-dropdown-item>
              <gl-dropdown-item>{{ $options.i18n.retryDownstreamPipeline }}</gl-dropdown-item>
            </gl-dropdown>
          </div>
          <gl-button
            :aria-label="$options.i18n.toggleSidebar"
            data-testid="sidebar-expansion-toggle"
            category="tertiary"
            class="gl-md-display-none gl-ml-2"
            icon="chevron-double-lg-right"
            @click="toggleSidebar"
          />
        </div>
        <!-- TODO: get job details and show commit block, stage dropdown, jobs list -->
      </div>
    </div>
  </aside>
</template>
