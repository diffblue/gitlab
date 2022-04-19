<script>
import { GlFormGroup, GlFormSelect, GlFormCheckbox, GlSprintf, GlLink, GlBadge } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import {
  SELECTIVE_SYNC_MORE_INFO,
  OBJECT_STORAGE_MORE_INFO,
  OBJECT_STORAGE_BETA,
} from '../constants';
import GeoNodeFormNamespaces from './geo_node_form_namespaces.vue';
import GeoNodeFormShards from './geo_node_form_shards.vue';

export default {
  name: 'GeoNodeFormSelectiveSync',
  i18n: {
    syncSettings: s__('Geo|Synchronization settings'),
    syncSubtitle: s__('Geo|Set what should be replicated by this secondary site.'),
    learnMore: __('Learn more'),
    selectiveSyncFieldLabel: s__('Geo|Selective synchronization'),
    selectiveSyncFieldDescription: s__('Geo|Choose specific groups or storage shards'),
    namespacesSelectFieldLabel: s__('Geo|Groups to synchronize'),
    shardsSelectFieldLabel: s__('Geo|Shards to synchronize'),
    objectStorageFieldLabel: s__('Geo|Object Storage replication'),
    objectStorageFieldDescription: s__(
      'Geo|If enabled, GitLab will handle Object Storage replication using Geo. %{linkStart}Learn more%{linkEnd}',
    ),
    objectStorageCheckboxLabel: s__(
      'Geo|Allow this secondary site to replicate content on Object Storage',
    ),
    beta: s__('Geo|Beta'),
  },
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
    <h2 class="gl-font-size-h2 gl-my-5">{{ $options.i18n.syncSettings }}</h2>
    <p class="gl-mb-5">
      {{ $options.i18n.syncSubtitle }}
      <gl-link
        :href="$options.SELECTIVE_SYNC_MORE_INFO"
        target="_blank"
        data-testid="selectiveSyncMoreInfo"
        >{{ $options.i18n.learnMore }}</gl-link
      >
    </p>
    <gl-form-group
      :label="$options.i18n.selectiveSyncFieldLabel"
      label-for="node-selective-synchronization-field"
      :description="$options.i18n.selectiveSyncFieldDescription"
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
      :label="$options.i18n.namespacesSelectFieldLabel"
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
      :label="$options.i18n.shardsSelectFieldLabel"
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
          $options.i18n.objectStorageFieldLabel
        }}</label>
        <gl-badge variant="info" size="sm" :href="$options.OBJECT_STORAGE_BETA" target="_blank">{{
          $options.i18n.beta
        }}</gl-badge>
      </template>
      <template #description>
        <gl-sprintf :message="$options.i18n.objectStorageFieldDescription">
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
        $options.i18n.objectStorageCheckboxLabel
      }}</gl-form-checkbox>
      <!-- eslint-enable vue/no-mutating-props -->
    </gl-form-group>
  </div>
</template>
