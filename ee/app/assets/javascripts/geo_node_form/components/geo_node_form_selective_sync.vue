<script>
import { GlFormGroup, GlFormSelect, GlFormCheckbox, GlSprintf, GlLink, GlBadge } from '@gitlab/ui';
import {
  SELECTIVE_SYNC_MORE_INFO,
  OBJECT_STORAGE_MORE_INFO,
  OBJECT_STORAGE_BETA,
} from '../constants';
import GeoNodeFormNamespaces from './geo_node_form_namespaces.vue';
import GeoNodeFormShards from './geo_node_form_shards.vue';

export default {
  name: 'GeoNodeFormSelectiveSync',
  components: {
    GlFormGroup,
    GlFormSelect,
    GeoNodeFormNamespaces,
    GeoNodeFormShards,
    GlFormCheckbox,
    GlSprintf,
    GlLink,
    GlBadge,
  },
  props: {
    nodeData: {
      type: Object,
      required: true,
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
  computed: {
    selectiveSyncNamespaces() {
      return this.nodeData.selectiveSyncType === this.selectiveSyncTypes.NAMESPACES.value;
    },
    selectiveSyncShards() {
      return this.nodeData.selectiveSyncType === this.selectiveSyncTypes.SHARDS.value;
    },
  },
  methods: {
    addSyncOption({ key, value }) {
      this.$emit('addSyncOption', { key, value });
    },
    removeSyncOption({ key, index }) {
      this.$emit('removeSyncOption', { key, index });
    },
  },
  SELECTIVE_SYNC_MORE_INFO,
  OBJECT_STORAGE_MORE_INFO,
  OBJECT_STORAGE_BETA,
};
</script>

<template>
  <div ref="geoNodeFormSelectiveSyncContainer">
    <h2 class="gl-font-size-h2 gl-my-5">{{ __('Synchronization settings') }}</h2>
    <p class="gl-mb-5">
      {{ __('Set what should be replicated by this secondary site.') }}
      <gl-link
        :href="$options.SELECTIVE_SYNC_MORE_INFO"
        target="_blank"
        data-testid="selectiveSyncMoreInfo"
        >{{ __('Learn more') }}</gl-link
      >
    </p>
    <gl-form-group
      :label="__('Selective synchronization')"
      label-for="node-selective-synchronization-field"
      :description="__('Choose specific groups or storage shards')"
    >
      <!-- eslint-disable vue/no-mutating-props -->
      <gl-form-select
        id="node-selective-synchronization-field"
        v-model="nodeData.selectiveSyncType"
        :options="selectiveSyncTypes"
        value-field="value"
        text-field="label"
        class="col-sm-3"
      />
      <!-- eslint-enable vue/no-mutating-props -->
    </gl-form-group>
    <gl-form-group
      v-if="selectiveSyncNamespaces"
      :label="__('Groups to synchronize')"
      label-for="node-synchronization-namespaces-field"
    >
      <geo-node-form-namespaces
        id="node-synchronization-namespaces-field"
        :selected-namespaces="nodeData.selectiveSyncNamespaceIds"
        @addSyncOption="addSyncOption"
        @removeSyncOption="removeSyncOption"
      />
    </gl-form-group>
    <gl-form-group
      v-if="selectiveSyncShards"
      :label="__('Shards to synchronize')"
      label-for="node-synchronization-shards-field"
    >
      <geo-node-form-shards
        id="node-synchronization-shards-field"
        :selected-shards="nodeData.selectiveSyncShards"
        :sync-shards-options="syncShardsOptions"
        @addSyncOption="addSyncOption"
        @removeSyncOption="removeSyncOption"
      />
    </gl-form-group>
    <gl-form-group>
      <template #label>
        <label for="node-object-storage-field" class="gl-mb-0">{{
          __('Object Storage replication')
        }}</label>
        <gl-badge variant="info" size="sm" :href="$options.OBJECT_STORAGE_BETA" target="_blank">{{
          __('Beta')
        }}</gl-badge>
      </template>
      <template #description>
        <gl-sprintf
          :message="
            __(
              'If enabled, GitLab will handle Object Storage replication using Geo. %{linkStart}Learn more%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              :href="$options.OBJECT_STORAGE_MORE_INFO"
              data-testid="objectStorageMoreInfo"
              target="_blank"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </template>
      <!-- eslint-disable vue/no-mutating-props -->
      <gl-form-checkbox id="node-object-storage-field" v-model="nodeData.syncObjectStorage">{{
        __('Allow this secondary site to replicate content on Object Storage')
      }}</gl-form-checkbox>
      <!-- eslint-enable vue/no-mutating-props -->
    </gl-form-group>
  </div>
</template>
