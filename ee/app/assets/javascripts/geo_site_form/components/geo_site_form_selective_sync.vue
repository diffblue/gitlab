<script>
import { GlFormGroup, GlFormSelect, GlFormCheckbox, GlLink, GlIcon, GlPopover } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { SELECTIVE_SYNC_MORE_INFO, OBJECT_STORAGE_MORE_INFO } from '../constants';
import GeoSiteFormNamespaces from './geo_site_form_namespaces.vue';
import GeoSiteFormShards from './geo_site_form_shards.vue';

export default {
  name: 'GeoSiteFormSelectiveSync',
  i18n: {
    syncSettings: s__('Geo|Synchronization settings'),
    syncSubtitle: s__('Geo|Set what should be replicated by this secondary site.'),
    learnMore: __('Learn more'),
    selectiveSyncFieldLabel: s__('Geo|Selective synchronization'),
    selectiveSyncFieldDescription: s__('Geo|Choose specific groups or storage shards'),
    selectiveSyncPopoverText: s__(
      'Geo|Geo allows you to choose specific groups or storage shards to replicate.',
    ),
    namespacesSelectFieldLabel: s__('Geo|Groups to synchronize'),
    shardsSelectFieldLabel: s__('Geo|Shards to synchronize'),
    objectStorageFieldLabel: s__('Geo|Object Storage replication'),
    objectStorageFieldDescription: s__(
      'Geo|If enabled, GitLab will handle Object Storage replication using Geo.',
    ),
    objectStorageFieldPopoverText: s__(
      'Geo|Geo can replicate objects stored in Object Storage (AWS S3, or other compatible object storage).',
    ),
    objectStorageCheckboxLabel: s__(
      'Geo|Allow this secondary site to replicate content on Object Storage',
    ),
  },
  components: {
    GlFormGroup,
    GlFormSelect,
    GeoSiteFormNamespaces,
    GeoSiteFormShards,
    GlFormCheckbox,
    GlLink,
    GlIcon,
    GlPopover,
  },
  props: {
    siteData: {
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
      return this.siteData.selectiveSyncType === this.selectiveSyncTypes.NAMESPACES.value;
    },
    selectiveSyncShards() {
      return this.siteData.selectiveSyncType === this.selectiveSyncTypes.SHARDS.value;
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
};
</script>

<template>
  <div ref="geoSiteFormSelectiveSyncContainer">
    <h2 class="gl-font-size-h2 gl-my-5">{{ $options.i18n.syncSettings }}</h2>
    <p class="gl-mb-5">
      {{ $options.i18n.syncSubtitle }}
    </p>
    <gl-form-group
      :description="$options.i18n.selectiveSyncFieldDescription"
      data-testid="selective-sync-form-group"
    >
      <template #label>
        <div class="gl-display-flex gl-align-items-center">
          <label for="site-selective-synchronization-field" class="gl-mb-0">{{
            $options.i18n.selectiveSyncFieldLabel
          }}</label>
          <gl-icon
            ref="selectiveSyncPopover"
            tabindex="0"
            name="question-o"
            class="gl-text-blue-600 gl-cursor-pointer gl-ml-2"
          />
          <gl-popover
            :target="() => $refs.selectiveSyncPopover.$el"
            placement="top"
            triggers="hover focus"
            :title="$options.i18n.selectiveSyncFieldLabel"
          >
            <p class="gl-font-base">
              {{ $options.i18n.selectiveSyncPopoverText }}
            </p>
            <gl-link :href="$options.SELECTIVE_SYNC_MORE_INFO" target="_blank">{{
              $options.i18n.learnMore
            }}</gl-link>
          </gl-popover>
        </div>
      </template>
      <!-- eslint-disable vue/no-mutating-props -->
      <gl-form-select
        id="site-selective-synchronization-field"
        v-model="siteData.selectiveSyncType"
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
      label-for="site-synchronization-namespaces-field"
    >
      <geo-site-form-namespaces
        id="site-synchronization-namespaces-field"
        :selected-namespaces="siteData.selectiveSyncNamespaceIds"
        @addSyncOption="addSyncOption"
        @removeSyncOption="removeSyncOption"
      />
    </gl-form-group>
    <gl-form-group
      v-if="selectiveSyncShards"
      :label="$options.i18n.shardsSelectFieldLabel"
      label-for="site-synchronization-shards-field"
    >
      <geo-site-form-shards
        id="site-synchronization-shards-field"
        :selected-shards="siteData.selectiveSyncShards"
        :sync-shards-options="syncShardsOptions"
        @addSyncOption="addSyncOption"
        @removeSyncOption="removeSyncOption"
      />
    </gl-form-group>
    <gl-form-group
      :description="$options.i18n.objectStorageFieldDescription"
      data-testid="object-storage-form-group"
    >
      <template #label>
        <div class="gl-display-flex gl-align-items-center">
          <label for="site-object-storage-field" class="gl-mb-0">{{
            $options.i18n.objectStorageFieldLabel
          }}</label>
          <gl-icon
            ref="objectStoragePopover"
            tabindex="0"
            name="question-o"
            class="gl-text-blue-600 gl-cursor-pointer gl-ml-2"
          />
          <gl-popover
            :target="() => $refs.objectStoragePopover.$el"
            placement="top"
            triggers="hover focus"
            :title="$options.i18n.objectStorageFieldLabel"
          >
            <p class="gl-font-base">
              {{ $options.i18n.objectStorageFieldPopoverText }}
            </p>
            <gl-link :href="$options.OBJECT_STORAGE_MORE_INFO" target="_blank">{{
              $options.i18n.learnMore
            }}</gl-link>
          </gl-popover>
        </div>
      </template>
      <!-- eslint-disable vue/no-mutating-props -->
      <gl-form-checkbox id="site-object-storage-field" v-model="siteData.syncObjectStorage">{{
        $options.i18n.objectStorageCheckboxLabel
      }}</gl-form-checkbox>
      <!-- eslint-enable vue/no-mutating-props -->
    </gl-form-group>
  </div>
</template>
