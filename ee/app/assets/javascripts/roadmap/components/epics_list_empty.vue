<script>
import { GlButton, GlSafeHtmlDirective } from '@gitlab/ui';
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
    GlButton,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
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
  },
};
</script>

<template>
  <div class="row empty-state">
    <div class="col-12">
      <div class="svg-content">
        <img :src="emptyStateIllustrationPath" data-testid="illustration" />
      </div>
    </div>
    <div class="col-12">
      <div class="text-content">
        <h4 data-testid="title">{{ message }}</h4>
        <p v-safe-html="subMessage" data-testid="sub-title"></p>

        <div class="gl-text-center">
          <gl-button
            v-if="canCreateEpic && !hasFiltersApplied"
            :href="newEpicPath"
            variant="confirm"
            class="gl-mt-3 gl-sm-mt-0! gl-w-full gl-sm-w-auto!"
            data-testid="new-epic-button"
          >
            {{ __('New epic') }}
          </gl-button>
          <gl-button
            :href="listEpicsPath"
            class="gl-mt-3 gl-sm-mt-0! gl-sm-ml-3 gl-w-full gl-sm-w-auto!"
            data-testid="list-epics-button"
          >
            {{ __('View epics list') }}
          </gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
