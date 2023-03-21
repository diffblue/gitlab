<script>
import { mapState } from 'vuex';
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlAlert,
  },
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
  <div class="gl-mb-3">
    <gl-alert v-if="loadingError" variant="danger" :dismissible="false">
      {{ $options.loadingFailedText }}
    </gl-alert>
    <div id="roadmap" class="roadmap-app border gl-rounded-base gl-bg-white">
      <div id="js-roadmap" v-bind="roadmapAttrs"></div>
    </div>
  </div>
</template>
