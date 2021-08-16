<script>
import { GlLink, GlButton, GlLoadingIcon, GlModal, GlSprintf } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { s__, __ } from '~/locale';
import { GEO_INFO_URL, REMOVE_NODE_MODAL_ID } from '../constants';
import GeoNodes from './geo_nodes.vue';
import GeoNodesEmptyState from './geo_nodes_empty_state.vue';

export default {
  name: 'GeoNodesApp',
  i18n: {
    geoSites: s__('Geo|Geo sites'),
    helpText: s__(
      'Geo|With GitLab Geo, you can install a special read-only and replicated instance anywhere. %{linkStart}Learn more%{linkEnd}',
    ),
    addSite: s__('Geo|Add site'),
    modalTitle: s__('Geo|Remove node'),
    modalBody: s__(
      'Geo|Removing a Geo node stops the synchronization to and from that node. Are you sure?',
    ),
    primarySite: s__('Geo|Primary site'),
    secondarySite: s__('Geo|Secondary site'),
  },
  components: {
    GlLink,
    GlButton,
    GlLoadingIcon,
    GeoNodes,
    GeoNodesEmptyState,
    GlModal,
    GlSprintf,
  },
  props: {
    newNodeUrl: {
      type: String,
      required: true,
    },
    geoNodesEmptyStateSvg: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['nodes', 'isLoading']),
    noNodes() {
      return !this.nodes || this.nodes.length === 0;
    },
    primaryNodes() {
      return this.nodes.filter((n) => n.primary);
    },
    secondaryNodes() {
      return this.nodes.filter((n) => !n.primary);
    },
  },
  created() {
    this.fetchNodes();
  },
  methods: {
    ...mapActions(['fetchNodes', 'cancelNodeRemoval', 'removeNode']),
  },
  GEO_INFO_URL,
  MODAL_PRIMARY_ACTION: {
    text: s__('Geo|Remove node'),
    attributes: {
      variant: 'danger',
    },
  },
  MODAL_CANCEL_ACTION: {
    text: __('Cancel'),
  },
  REMOVE_NODE_MODAL_ID,
};
</script>

<template>
  <section>
    <h3>{{ $options.i18n.geoSites }}</h3>
    <div
      class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-md-align-items-center gl-pb-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
    >
      <div class="gl-mr-5">
        <gl-sprintf :message="$options.i18n.helpText">
          <template #link="{ content }">
            <gl-link :href="$options.GEO_INFO_URL" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </div>
      <gl-button
        v-if="!noNodes"
        class="gl-w-full gl-md-w-auto gl-ml-auto gl-mr-5 gl-mt-5 gl-md-mt-0"
        variant="confirm"
        :href="newNodeUrl"
        target="_blank"
        data-qa-selector="add_site_button"
        >{{ $options.i18n.addSite }}
      </gl-button>
    </div>
    <gl-loading-icon v-if="isLoading" size="xl" class="gl-mt-5" />
    <template v-if="!isLoading">
      <div v-if="!noNodes">
        <h4 class="gl-font-lg gl-my-5">{{ $options.i18n.primarySite }}</h4>
        <geo-nodes
          v-for="node in primaryNodes"
          :key="node.id"
          :node="node"
          data-testid="primary-nodes"
        />
        <h4 class="gl-font-lg gl-my-5">{{ $options.i18n.secondarySite }}</h4>
        <geo-nodes
          v-for="node in secondaryNodes"
          :key="node.id"
          :node="node"
          data-testid="secondary-nodes"
        />
      </div>
      <geo-nodes-empty-state v-else :svg-path="geoNodesEmptyStateSvg" />
    </template>
    <gl-modal
      :modal-id="$options.REMOVE_NODE_MODAL_ID"
      :title="$options.i18n.modalTitle"
      :action-primary="$options.MODAL_PRIMARY_ACTION"
      :action-cancel="$options.MODAL_CANCEL_ACTION"
      @primary="removeNode"
      @cancel="cancelNodeRemoval"
    >
      {{ $options.i18n.modalBody }}
    </gl-modal>
  </section>
</template>
