<script>
import { createAlert } from '~/flash';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import getJobArtifactsQuery from '../graphql/queries/get_job_artifacts.query.graphql';
import destroyArtifactMutation from '../graphql/mutations/destroy_artifact.mutation.graphql';
import { removeArtifactFromStore } from '../graphql/cache_update';
import { i18n } from '../constants';
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
  methods: {
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
};
</script>
<template>
  <div style="max-height: 222px">
    <dynamic-scroller :items="artifacts.nodes" :min-item-size="64">
      <template #default="{ item, index, active }">
        <dynamic-scroller-item :item="item" :active="active" :class="{ active }">
          <div
            :class="{
              'gl-border-b-solid gl-border-b-1 gl-border-gray-100':
                index !== artifacts.nodes.length - 1,
            }"
            class="gl-py-5"
          >
            <artifact-row
              :artifact="item"
              :deleting="item.id === deletingArtifactId"
              @delete="destroyArtifact(item.id)"
            />
          </div>
        </dynamic-scroller-item>
      </template>
    </dynamic-scroller>
  </div>
</template>
