<script>
import { GlEmptyState } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { dateInWords } from '~/lib/utils/datetime_utility';
import { s__, sprintf } from '~/locale';

import {
  emptyStateDefault,
  emptyStateWithFilters,
  emptyStateWithEpicIidFiltered,
} from '../constants';
import CommonMixin from '../mixins/common_mixin';

export default {
  components: {
    GlEmptyState,
  },
  directives: {
    SafeHtml,
  },
  mixins: [CommonMixin],
  inject: ['newEpicPath', 'listEpicsPath', 'epicsDocsPath', 'canCreateEpic'],
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframeStart: {
      type: [Date, Object],
      required: true,
    },
    timeframeEnd: {
      type: [Date, Object],
      required: true,
    },
    hasFiltersApplied: {
      type: Boolean,
      required: true,
    },
    emptyStateIllustrationPath: {
      type: String,
      required: true,
    },
    isChildEpics: {
      type: Boolean,
      required: false,
      default: false,
    },
    filterParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    timeframeRange() {
      let startDate;
      let endDate;

      if (this.presetTypeQuarters) {
        const quarterStart = this.timeframeStart.range[0];
        const quarterEnd = this.timeframeEnd.range[2];
        startDate = dateInWords(
          quarterStart,
          true,
          quarterStart.getFullYear() === quarterEnd.getFullYear(),
        );
        endDate = dateInWords(quarterEnd, true);
      } else if (this.presetTypeMonths) {
        startDate = dateInWords(
          this.timeframeStart,
          true,
          this.timeframeStart.getFullYear() === this.timeframeEnd.getFullYear(),
        );
        endDate = dateInWords(this.timeframeEnd, true);
      } else if (this.presetTypeWeeks) {
        const end = new Date(this.timeframeEnd.getTime());
        end.setDate(end.getDate() + 6);

        startDate = dateInWords(
          this.timeframeStart,
          true,
          this.timeframeStart.getFullYear() === end.getFullYear(),
        );
        endDate = dateInWords(end, true);
      }

      return {
        startDate,
        endDate,
      };
    },
    message() {
      if (this.hasFiltersApplied) {
        return s__('GroupRoadmap|Sorry, no epics matched your search');
      }
      return s__('GroupRoadmap|The roadmap shows the progress of your epics along a timeline');
    },
    subMessage() {
      if (this.isChildEpics) {
        return sprintf(
          s__(
            'GroupRoadmap|To view the roadmap, add a start or due date to one of the %{linkStart}child epics%{linkEnd}.',
          ),
          {
            linkStart: `<a href="${this.epicsDocsPath}#multi-level-child-epics" target="_blank" rel="noopener noreferrer nofollow">`,
            linkEnd: '</a>',
          },
          false,
        );
      }

      if (this.hasFiltersApplied && Boolean(this.filterParams?.epicIid)) {
        return emptyStateWithEpicIidFiltered;
      }

      if (this.hasFiltersApplied) {
        return sprintf(emptyStateWithFilters, {
          startDate: this.timeframeRange.startDate,
          endDate: this.timeframeRange.endDate,
        });
      }
      return sprintf(emptyStateDefault, {
        startDate: this.timeframeRange.startDate,
        endDate: this.timeframeRange.endDate,
      });
    },
    extraProps() {
      const props = {};

      if (this.canCreateEpic && !this.hasFiltersApplied) {
        props.primaryButtonLink = this.newEpicPath;
        props.primaryButtonText = s__('GroupRoadmap|New epic');
      }

      return {
        secondaryButtonLink: this.listEpicsPath,
        secondaryButtonText: s__('GroupRoadmap|View epics list'),
        ...props,
      };
    },
  },
};
</script>

<template>
  <gl-empty-state :title="message" :svg-path="emptyStateIllustrationPath" v-bind="extraProps">
    <template #description>
      <p v-safe-html="subMessage" data-testid="sub-title"></p>
    </template>
  </gl-empty-state>
</template>
