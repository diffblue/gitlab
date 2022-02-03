import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mapActions } from 'vuex';

import { parseBoolean, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import { queryToObject } from '~/lib/utils/url_utility';
import Translate from '~/vue_shared/translate';

import EpicItem from './components/epic_item.vue';
import EpicItemContainer from './components/epic_item_container.vue';

import roadmapApp from './components/roadmap_app.vue';
import { DATE_RANGES } from './constants';

import createStore from './store';
import {
  getPresetTypeForTimeframeRangeType,
  getTimeframeForRangeType,
} from './utils/roadmap_utils';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-roadmap');

  if (!el) {
    return false;
  }

  Vue.use(VueApollo);
  const defaultClient = createDefaultClient();
  const apolloProvider = new VueApollo({
    defaultClient,
  });

  Vue.component('EpicItem', EpicItem);
  Vue.component('EpicItemContainer', EpicItemContainer);

  return new Vue({
    el,
    apolloProvider,
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

      const timeframeRangeType =
        Object.keys(DATE_RANGES).indexOf(dataset.timeframeRangeType) > -1
          ? dataset.timeframeRangeType
          : DATE_RANGES.CURRENT_QUARTER;
      const presetType = getPresetTypeForTimeframeRangeType(timeframeRangeType, dataset.presetType);
      const timeframe = getTimeframeForRangeType({
        timeframeRangeType,
        presetType,
      });

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
          emptyStateIllustrationPath: this.emptyStateIllustrationPath,
        },
      });
    },
  });
};
