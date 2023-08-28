<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams, removeParams } from '~/lib/utils/url_utility';
import { GroupByParamType } from 'ee_else_ce/boards/constants';

const trackingMixin = Tracking.mixin();

const EPIC_KEY = 'epic';
const NO_GROUPING_KEY = 'no_grouping';

const LIST_BOX_ITEMS = [
  {
    value: NO_GROUPING_KEY,
    text: __('No grouping'),
  },
  {
    value: EPIC_KEY,
    text: __('Epic'),
  },
];

export default {
  LIST_BOX_ITEMS,
  components: {
    GlCollapsibleListbox,
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
    dropdownLabel() {
      return this.isSwimlanesOn ? LIST_BOX_ITEMS[1].text : __('None');
    },
    selected() {
      return this.isSwimlanesOn ? EPIC_KEY : NO_GROUPING_KEY;
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
  <div class="gl-md-display-flex gl-align-items-center gl-ml-3">
    <label
      for="swimlane-listbox"
      class="gl-white-space-nowrap gl-font-weight-bold gl-line-height-normal gl-m-0"
      data-testid="toggle-swimlanes-label"
    >
      {{ __('Group by') }}
    </label>
    <gl-collapsible-listbox
      id="swimlane-listbox"
      toggle-class="gl-ml-3 gl-line-height-normal!"
      placement="right"
      :items="$options.LIST_BOX_ITEMS"
      :toggle-text="dropdownLabel"
      :selected="selected"
      @select="onToggle"
    />
  </div>
</template>
