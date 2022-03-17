<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import initRelatedItemsTree from 'ee/related_items_tree/related_items_tree_bundle';

const displayNoneClass = 'gl-display-none';
const containerClass = 'container-limited';

export default {
  components: {
    GlButton,
    GlButtonGroup,
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
      activeButton: this.$options.TABS.TREE,
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
      this.activeButton = this.$options.TABS.TREE;
      this.roadmapElement.classList.add(displayNoneClass);
      this.treeElement.classList.remove(displayNoneClass);
      this.containerElement.classList.add(containerClass);
    },
    showRoadmapTabContent() {
      this.activeButton = this.$options.TABS.ROADMAP;
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
  TABS: {
    TREE: 'related_items_tree',
    ROADMAP: 'roadmap',
  },
};
</script>
<template>
  <div class="epic-tabs-holder gl-pl-0 gl-pr-0 gl-ml-0 gl-mr-0">
    <div class="epic-tabs-container gl-pt-3 gl-pb-3">
      <gl-button-group data-testid="tabs">
        <gl-button
          class="js-epic-tree-tab"
          data-testid="epic-tree-tab"
          :selected="activeButton === $options.TABS.TREE"
          @click="onTreeTabClick"
        >
          {{ allowSubEpics ? __('Epics and Issues') : __('Issues') }}
        </gl-button>
        <gl-button
          v-if="allowSubEpics"
          class="js-epic-roadmap-tab"
          data-testid="epic-roadmap-tab"
          :selected="activeButton === $options.TABS.ROADMAP"
          @click="onRoadmapTabClick"
        >
          {{ __('Roadmap') }}
        </gl-button>
      </gl-button-group>
    </div>
  </div>
</template>
