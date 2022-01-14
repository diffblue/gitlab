<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import initRelatedItemsTree from 'ee/related_items_tree/related_items_tree_bundle';

const displayNoneClass = 'gl-display-none';
const containerClass = 'container-limited';

export default {
  components: {
    GlTabs,
    GlTab,
  },
  inject: {
    allowSubEpics: {
      default: false,
    },
    treeElementSelector: {
      default: null,
    },
    roadmapElementSelector: {
      default: null,
    },
    containerElementSelector: {
      default: null,
    },
  },
  data() {
    return {
      roadmapLoaded: false,
    };
  },
  computed: {
    shouldLoadRoadmap() {
      return !this.roadmapLoaded && this.allowSubEpics;
    },
  },
  mounted() {
    initRelatedItemsTree();
  },
  beforeMount() {
    this.treeElement = document.querySelector(this.treeElementSelector);
    this.roadmapElement = document.querySelector(this.roadmapElementSelector);
    this.containerElement = document.querySelector(this.containerElementSelector);
  },
  methods: {
    initRoadmap() {
      return import('ee/roadmap/roadmap_bundle')
        .then((roadmapBundle) => {
          roadmapBundle.default();
        })
        .catch(() => {});
    },
    onTreeTabClick() {
      this.roadmapElement.classList.add(displayNoneClass);
      this.treeElement.classList.remove(displayNoneClass);
      this.containerElement.classList.add(containerClass);
    },
    showRoadmapTabContent() {
      this.roadmapElement.classList.remove(displayNoneClass);
      this.treeElement.classList.add(displayNoneClass);
      this.containerElement.classList.remove(containerClass);
    },
    onRoadmapTabClick() {
      if (this.shouldLoadRoadmap) {
        this.initRoadmap()
          .then(() => {
            this.roadmapLoaded = true;
            this.showRoadmapTabContent();
          })
          .catch(() => {});
      } else {
        this.showRoadmapTabContent();
      }
    },
  },
};
</script>
<template>
  <gl-tabs
    content-class="gl-display-none"
    nav-wrapper-class="epic-tabs-container"
    nav-class="gl-border-bottom-0"
    class="epic-tabs-holder"
    data-testid="tabs"
  >
    <gl-tab title-link-class="js-epic-tree-tab" data-testid="epic-tree-tab" @click="onTreeTabClick">
      <template #title>{{ allowSubEpics ? __('Epics and Issues') : __('Issues') }}</template>
    </gl-tab>
    <gl-tab
      v-if="allowSubEpics"
      title-link-class="js-epic-roadmap-tab"
      data-testid="epic-roadmap-tab"
      @click="onRoadmapTabClick"
    >
      <template #title>{{ __('Roadmap') }}</template>
    </gl-tab>
  </gl-tabs>
</template>
