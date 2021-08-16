<script>
import { GlButton, GlLink, GlModalDirective, GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';
import { INSTALL_AGENT_MODAL_ID } from '../constants';

export default {
  modalId: INSTALL_AGENT_MODAL_ID,
  components: {
    GlButton,
    GlLink,
    GlTable,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['integrationDocsUrl'],
  props: {
    agents: {
      required: true,
      type: Array,
    },
  },
  computed: {
    fields() {
      return [
        {
          key: 'name',
          label: s__('ClusterAgents|Name'),
        },
        {
          key: 'configuration',
          label: s__('ClusterAgents|Configuration'),
        },
      ];
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-block gl-text-right gl-my-3">
      <gl-button v-gl-modal-directive="$options.modalId" variant="success" category="primary"
        >{{ s__('ClusterAgents|Install a new GitLab Agent') }}
      </gl-button>
    </div>

    <gl-table :items="agents" :fields="fields" stacked="md" data-testid="cluster-agent-list-table">
      <template #cell(name)="{ item }">
        <gl-link :href="item.webPath">
          {{ item.name }}
        </gl-link>
      </template>

      <template #cell(configuration)="{ item }">
        <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
        <gl-link v-if="item.configFolder" :href="item.configFolder.webPath">
          .gitlab/agents/{{ item.name }}
        </gl-link>

        <p v-else>.gitlab/agents/{{ item.name }}</p>
      </template>
    </gl-table>
  </div>
</template>
