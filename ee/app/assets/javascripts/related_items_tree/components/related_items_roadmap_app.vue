<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { GlAlert } from '@gitlab/ui';
import Tracking from '~/tracking';
import { __ } from '~/locale';
import { ROADMAP_ACTIVITY_TRACK_LABEL, ROADMAP_ACTIVITY_TRACK_ACTION_LABEL } from '../constants';

export default {
  components: {
    GlAlert,
  },
  mixins: [Tracking.mixin()],
  inject: ['roadmapAppData'],
  data() {
    return {
      loadingError: false,
      roadmapLoaded: false,
    };
  },
  computed: {
    ...mapState(['allowSubEpics']),
    roadmapAttrs() {
      if (!this.roadmapAppData) {
        return {};
      }

      return Object.keys(this.roadmapAppData).reduce((acc, key) => {
        const hypenCasedKey = key.replace(/_/g, '-');
        acc[`data-${hypenCasedKey}`] = this.roadmapAppData[key];
        return acc;
      }, {});
    },
    shouldLoadRoadmap() {
      return !this.roadmapLoaded && this.allowSubEpics;
    },
  },
  mounted() {
    if (this.shouldLoadRoadmap) {
      this.initRoadmap();
    }
  },
  methods: {
    initRoadmap() {
      return import('ee/roadmap/roadmap_bundle')
        .then((roadmapBundle) => {
          roadmapBundle.default();
          this.roadmapLoaded = true;
          this.track(ROADMAP_ACTIVITY_TRACK_ACTION_LABEL, { label: ROADMAP_ACTIVITY_TRACK_LABEL });
        })
        .catch(() => {
          this.loadingError = true;
        });
    },
  },
  loadingFailedText: __('Failed to load Roadmap'),
};
</script>

<template>
  <div id="roadmap" class="roadmap-app gl-rounded-bottom-base gl-border-t gl-bg-white">
    <gl-alert v-if="loadingError" variant="danger" :dismissible="false">
      {{ $options.loadingFailedText }}
    </gl-alert>
    <div id="js-roadmap" v-bind="roadmapAttrs"></div>
  </div>
</template>
