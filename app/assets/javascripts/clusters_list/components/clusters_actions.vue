<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlModalDirective,
  GlTooltipDirective,
  GlDropdownDivider,
  GlDropdownSectionHeader,
} from '@gitlab/ui';

import { INSTALL_AGENT_MODAL_ID, CLUSTERS_ACTIONS } from '../constants';

export default {
  i18n: CLUSTERS_ACTIONS,
  INSTALL_AGENT_MODAL_ID,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlDropdownSectionHeader,
  },
  directives: {
    GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'newClusterPath',
    'addClusterPath',
    'newClusterDocsPath',
    'canAddCluster',
    'displayClusterAgents',
    'certificateBasedClustersEnabled',
  ],
  computed: {
    tooltip() {
      const { connectWithAgent, connectExistingCluster, dropdownDisabledHint } = this.$options.i18n;

      if (!this.canAddCluster) {
        return dropdownDisabledHint;
      } else if (this.displayClusterAgents) {
        return connectWithAgent;
      }

      return connectExistingCluster;
    },
    shouldTriggerModal() {
      return this.canAddCluster && this.displayClusterAgents;
    },
    hasSectionHeaders() {
      return this.displayClusterAgents && this.certificateBasedClustersEnabled;
    },
  },
};
</script>

<template>
  <div class="nav-controls gl-ml-auto">
    <gl-dropdown
      ref="dropdown"
      v-gl-modal-directive="shouldTriggerModal && $options.INSTALL_AGENT_MODAL_ID"
      v-gl-tooltip="tooltip"
      category="primary"
      variant="confirm"
      :text="$options.i18n.actionsButton"
      :disabled="!canAddCluster"
      :split="displayClusterAgents"
      right
    >
      <gl-dropdown-section-header v-if="hasSectionHeaders">{{
        $options.i18n.agent
      }}</gl-dropdown-section-header>

      <template v-if="displayClusterAgents">
        <gl-dropdown-item
          v-gl-modal-directive="$options.INSTALL_AGENT_MODAL_ID"
          data-testid="connect-new-agent-link"
        >
          {{ $options.i18n.connectWithAgent }}
        </gl-dropdown-item>
        <gl-dropdown-item :href="newClusterDocsPath" data-testid="create-cluster-link" @click.stop>
          {{ $options.i18n.createAndConnectCluster }}
        </gl-dropdown-item>
      </template>

      <template v-if="hasSectionHeaders">
        <gl-dropdown-divider />
        <gl-dropdown-section-header>{{ $options.i18n.certificate }}</gl-dropdown-section-header>
      </template>

      <template v-if="certificateBasedClustersEnabled">
        <gl-dropdown-item :href="newClusterPath" data-testid="new-cluster-link" @click.stop>
          {{ $options.i18n.createNewCluster }}
        </gl-dropdown-item>

        <gl-dropdown-item :href="addClusterPath" data-testid="connect-cluster-link" @click.stop>
          {{ $options.i18n.connectExistingCluster }}
        </gl-dropdown-item>
      </template>
    </gl-dropdown>
  </div>
</template>
