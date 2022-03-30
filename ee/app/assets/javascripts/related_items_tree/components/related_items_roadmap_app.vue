<script>
import { mapState } from 'vuex';

export default {
  inject: ['roadmapAppData'],
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
      this.initRoadmap()
        .then(() => {
          this.roadmapLoaded = true;
        })
        .catch(() => {});
    }
  },
  methods: {
    initRoadmap() {
      return import('ee/roadmap/roadmap_bundle')
        .then((roadmapBundle) => {
          roadmapBundle.default();
        })
        .catch(() => {});
    },
  },
};
</script>

<template>
  <div class="gl-px-3 gl-py-3 gl-bg-gray-10">
    <div id="roadmap" class="roadmap-app border gl-rounded-base gl-bg-white">
      <div id="js-roadmap" v-bind="roadmapAttrs"></div>
    </div>
  </div>
</template>
