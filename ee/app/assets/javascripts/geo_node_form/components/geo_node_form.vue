<script>
import { GlButton } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { visitUrl } from '~/lib/utils/url_utility';
import GeoNodeFormCapacities from './geo_node_form_capacities.vue';
import GeoNodeFormCore from './geo_node_form_core.vue';
import GeoNodeFormSelectiveSync from './geo_node_form_selective_sync.vue';

export default {
  name: 'GeoNodeForm',
  components: {
    GlButton,
    GeoNodeFormCore,
    GeoNodeFormSelectiveSync,
    GeoNodeFormCapacities,
  },
  props: {
    node: {
      type: Object,
      required: false,
      default: null,
    },
    selectiveSyncTypes: {
      type: Object,
      required: true,
    },
    syncShardsOptions: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      nodeData: {
        name: '',
        url: '',
        primary: false,
        internalUrl: '',
        selectiveSyncType: '',
        selectiveSyncNamespaceIds: [],
        selectiveSyncShards: [],
        reposMaxCapacity: 25,
        filesMaxCapacity: 10,
        verificationMaxCapacity: 100,
        containerRepositoriesMaxCapacity: 10,
        minimumReverificationInterval: 7,
        syncObjectStorage: false,
      },
    };
  },
  computed: {
    ...mapGetters(['formHasError']),
    ...mapState(['nodesPath']),
  },
  created() {
    if (this.node) {
      this.nodeData = { ...this.node };
    }
  },
  methods: {
    ...mapActions(['saveGeoNode']),
    redirect() {
      visitUrl(this.nodesPath);
    },
    addSyncOption({ key, value }) {
      this.nodeData[key].push(value);
    },
    removeSyncOption({ key, index }) {
      this.nodeData[key].splice(index, 1);
    },
  },
};
</script>

<template>
  <form>
    <geo-node-form-core
      :node-data="nodeData"
      class="gl-pb-4 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid"
    />
    <geo-node-form-selective-sync
      v-if="!nodeData.primary"
      class="gl-pb-4 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid"
      :node-data="nodeData"
      :selective-sync-types="selectiveSyncTypes"
      :sync-shards-options="syncShardsOptions"
      @addSyncOption="addSyncOption"
      @removeSyncOption="removeSyncOption"
    />
    <geo-node-form-capacities :node-data="nodeData" />
    <section
      class="gl-display-flex gl-align-items-center gl-p-5 gl-mt-6 gl-bg-gray-10 gl-border-t-solid gl-border-t-1 gl-border-gray-100"
    >
      <gl-button
        id="node-save-button"
        data-qa-selector="add_node_button"
        class="gl-mr-5"
        variant="info"
        :disabled="formHasError"
        @click="saveGeoNode(nodeData)"
        >{{ __('Save changes') }}</gl-button
      >
      <gl-button id="node-cancel-button" @click="redirect">{{ __('Cancel') }}</gl-button>
    </section>
  </form>
</template>
