<script>
import { GlTableLite } from '@gitlab/ui';
import { __ } from '~/locale';
import environmentDetailsQuery from '../graphql/queries/environment_details.query.graphql';

export default {
  components: {
    GlTableLite,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    environmentName: {
      type: String,
      required: true,
    },
  },
  apollo: {
    project: {
      query: environmentDetailsQuery,
      variables() {
        return {
          projectFullPath: this.projectFullPath,
          environmentName: this.environmentName,
        };
      },
    },
  },
  data() {
    return {
      project: {
        loading: true,
      },
      loading: 0,
      fields: [
        {
          key: 'column_one',
          label: __('Column One'),
          thClass: 'w-60p',
          tdClass: 'table-col d-flex',
        },
        {
          key: 'col_2',
          label: __('Column 2'),
          thClass: 'w-15p',
          tdClass: 'table-col d-flex',
        },
      ],
    };
  },
  computed: {
    deployments() {
      return this.project.loading ? [] : this.project.environments.nodes[0].deployments.nodes;
    },
  },
};
</script>
<template>
  <div>
    <div v-if="project.loading">{{ __('The query is running') }}</div>
    <gl-table-lite :items="deployments">
      <!-- <template #head(column_one)>
        <div>Column one</div>
      </template>
      <template #cell(column_one)>
        <div>the template for the cell</div>
      </template>
      <template #cell(col_2)>
        <div>col_2</div>
      </template> -->
    </gl-table-lite>
  </div>
</template>
