<script>
import { mapActions } from 'vuex';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams, removeParams } from '~/lib/utils/url_utility';
import { GroupByParamType } from 'ee_else_ce/boards/constants';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  mixins: [trackingMixin],
  inject: ['isApolloBoard'],
  props: {
    isSwimlanesOn: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    groupByEpicLabel() {
      return __('Epic');
    },
    groupByNoneLabel() {
      return __('No grouping');
    },
    dropdownLabel() {
      return this.isSwimlanesOn ? this.groupByEpicLabel : __('None');
    },
  },
  methods: {
    ...mapActions(['fetchEpicsSwimlanes', 'fetchLists']),
    toggleEpicSwimlanes() {
      if (this.isSwimlanesOn) {
        historyPushState(removeParams(['group_by']), window.location.href, true);
        this.$emit('toggleSwimlanes', false);
      } else {
        historyPushState(
          mergeUrlParams({ group_by: GroupByParamType.epic }, window.location.href, {
            spreadArrays: true,
          }),
        );
        this.$emit('toggleSwimlanes', true);
        if (!this.isApolloBoard) {
          this.fetchEpicsSwimlanes();
          this.fetchLists();
        }
      }
    },
    onToggle() {
      // Track toggle event
      this.track('click_toggle_swimlanes_button', {
        label: 'toggle_swimlanes',
        property: this.isSwimlanesOn ? 'off' : 'on',
      });

      // Track if the board has swimlane active
      if (!this.isSwimlanesOn) {
        this.track('click_toggle_swimlanes_button', {
          label: 'swimlanes_active',
        });
      }

      this.toggleEpicSwimlanes();
    },
  },
};
</script>

<template>
  <div
    class="board-swimlanes-toggle-wrapper gl-md-display-flex gl-align-items-center gl-ml-3"
    data-testid="toggle-swimlanes"
  >
    <span
      class="board-swimlanes-toggle-text gl-white-space-nowrap gl-font-weight-bold gl-line-height-normal"
      data-testid="toggle-swimlanes-label"
    >
      {{ __('Group by') }}
    </span>
    <gl-dropdown right :text="dropdownLabel" class="gl-ml-3" toggle-class="gl-line-height-normal!">
      <gl-dropdown-item is-check-item :is-checked="!isSwimlanesOn" @click="onToggle">{{
        groupByNoneLabel
      }}</gl-dropdown-item>
      <gl-dropdown-item is-check-item :is-checked="isSwimlanesOn" @click="onToggle">{{
        groupByEpicLabel
      }}</gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
