<script>
import { createAlert } from '~/flash';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import getJobArtifactsQuery from '../graphql/queries/get_job_artifacts.query.graphql';
import destroyArtifactMutation from '../graphql/mutations/destroy_artifact.mutation.graphql';
import { removeArtifactFromStore } from '../graphql/cache_update';
import { i18n, ROW_HEIGHT } from '../constants';
import ArtifactRow from './artifact_row.vue';

export default {
  name: 'ArtifactsTableRowDetails',
  components: {
    DynamicScroller,
    DynamicScrollerItem,
    ArtifactRow,
  },
  props: {
    artifacts: {
      type: Object,
      required: true,
    },
    refetchArtifacts: {
      type: Function,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      deletingArtifactId: null,
    };
  },
  computed: {
    scrollContainerStyle() {
      return { maxHeight: `${4 * (ROW_HEIGHT + 1)}px` };
    },
  },
  methods: {
    isLastRow(index) {
      return index === this.artifacts.nodes.length - 1;
    },
    destroyArtifact(id) {
      this.deletingArtifactId = id;
      this.$apollo
        .mutate({
          mutation: destroyArtifactMutation,
          variables: { id },
          update: (store) => {
            removeArtifactFromStore(store, id, getJobArtifactsQuery, this.queryVariables);
          },
        })
        .catch(() => {
          createAlert({
            message: i18n.destroyArtifactError,
          });
          this.refetchArtifacts();
        })
        .finally(() => {
          this.deletingArtifactId = null;
        });
    },
  },
  ROW_HEIGHT,
};
</script>
<template>
  <div :style="scrollContainerStyle">
    <dynamic-scroller :items="artifacts.nodes" :min-item-size="$options.ROW_HEIGHT">
      <template #default="{ item, index, active }">
        <dynamic-scroller-item :item="item" :active="active" :class="{ active }">
          <artifact-row
            :artifact="item"
            :is-last-row="isLastRow(index)"
            :is-loading="item.id === deletingArtifactId"
            @delete="destroyArtifact(item.id)"
          />
        </dynamic-scroller-item>
      </template>
    </dynamic-scroller>
  </div>
</template>
