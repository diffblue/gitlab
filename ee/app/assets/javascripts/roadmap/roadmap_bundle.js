import Vue from 'vue';
import { mapActions } from 'vuex';

import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { visitUrl, mergeUrlParams, queryToObject } from '~/lib/utils/url_utility';
import Translate from '~/vue_shared/translate';

import EpicItem from './components/epic_item.vue';
import EpicItemContainer from './components/epic_item_container.vue';

import roadmapApp from './components/roadmap_app.vue';
import { PRESET_TYPES, EPIC_DETAILS_CELL_WIDTH, DATE_RANGES } from './constants';

import createStore from './store';
import {
  getTimeframeForPreset,
  getPresetTypeForTimeframeRangeType,
  getTimeframeForRangeType,
} from './utils/roadmap_utils';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-roadmap');
  const presetButtonsContainer = document.querySelector('.js-btn-roadmap-presets');

  if (!el) {
    return false;
  }

  // This event handler is to be removed in 11.1 once
  // we allow user to save selected preset in db
  if (presetButtonsContainer) {
    presetButtonsContainer.addEventListener('click', (e) => {
      const presetType = e.target.querySelector('input[name="presetType"]').value;

      visitUrl(mergeUrlParams({ layout: presetType }, window.location.href));
    });
  }

  Vue.component('EpicItem', EpicItem);
  Vue.component('EpicItemContainer', EpicItemContainer);

  return new Vue({
    el,
    apolloProvider: {},
    store: createStore(),
    components: {
      roadmapApp,
    },
    provide() {
      const { dataset } = this.$options.el;

      return {
        newEpicPath: dataset.newEpicPath,
        listEpicsPath: dataset.listEpicsPath,
        epicsDocsPath: dataset.epicsDocsPath,
        groupFullPath: dataset.fullPath,
        groupLabelsPath: dataset.groupLabelsEndpoint,
        groupMilestonesPath: dataset.groupMilestonesEndpoint,
      };
    },
    data() {
      const { dataset } = this.$options.el;
      let timeframe;
      let timeframeRangeType;
      let presetType;

      if (gon.features.roadmapDaterangeFilter) {
        timeframeRangeType =
          Object.keys(DATE_RANGES).indexOf(dataset.timeframeRangeType) > -1
            ? dataset.timeframeRangeType
            : DATE_RANGES.CURRENT_QUARTER;
        presetType = getPresetTypeForTimeframeRangeType(timeframeRangeType, dataset.presetType);
        timeframe = getTimeframeForRangeType({
          timeframeRangeType,
          presetType,
        });
      } else {
        presetType =
          Object.keys(PRESET_TYPES).indexOf(dataset.presetType) > -1
            ? dataset.presetType
            : PRESET_TYPES.MONTHS;
        timeframe = getTimeframeForPreset(
          presetType,
          window.innerWidth - el.offsetLeft - EPIC_DETAILS_CELL_WIDTH,
        );
      }

      const rawFilterParams = queryToObject(window.location.search, {
        gatherArrays: true,
      });
      const filterParams = {
        ...convertObjectPropsToCamelCase(rawFilterParams, {
          dropKeys: ['scope', 'utf8', 'state', 'sort', 'timeframe_range_type', 'layout'], // These keys are unsupported/unnecessary
        }),
        // We shall put parsed value of `confidential` only
        // when it is defined.
        ...(rawFilterParams.confidential && {
          confidential: parseBoolean(rawFilterParams.confidential),
        }),

        ...(rawFilterParams.epicIid && {
          epicIid: rawFilterParams.epicIid,
        }),
      };

      return {
        emptyStateIllustrationPath: dataset.emptyStateIllustration,
        hasFiltersApplied: parseBoolean(dataset.hasFiltersApplied),
        allowSubEpics: parseBoolean(dataset.allowSubEpics),
        defaultInnerHeight: Number(dataset.innerHeight),
        isChildEpics: parseBoolean(dataset.childEpics),
        currentGroupId: parseInt(dataset.groupId, 10),
        basePath: dataset.epicsPath,
        fullPath: dataset.fullPath,
        epicIid: dataset.iid,
        epicsState: dataset.epicsState,
        sortedBy: dataset.sortedBy,
        filterParams,
        timeframeRangeType,
        presetType,
        timeframe,
      };
    },
    created() {
      this.setInitialData({
        currentGroupId: this.currentGroupId,
        fullPath: this.fullPath,
        epicIid: this.epicIid,
        sortedBy: this.sortedBy,
        timeframeRangeType: this.timeframeRangeType,
        presetType: this.presetType,
        epicsState: this.epicsState,
        timeframe: this.timeframe,
        basePath: this.basePath,
        filterParams: this.filterParams,
        defaultInnerHeight: this.defaultInnerHeight,
        isChildEpics: this.isChildEpics,
        hasFiltersApplied: this.hasFiltersApplied,
        allowSubEpics: this.allowSubEpics,
      });
    },
    methods: {
      ...mapActions(['setInitialData']),
    },
    render(createElement) {
      return createElement('roadmap-app', {
        props: {
          timeframeRangeType: this.timeframeRangeType,
          presetType: this.presetType,
          emptyStateIllustrationPath: this.emptyStateIllustrationPath,
        },
      });
    },
  });
};
