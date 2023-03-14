<script>
import { GlButton } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { __ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import GeoSiteFormCapacities from './geo_site_form_capacities.vue';
import GeoSiteFormCore from './geo_site_form_core.vue';
import GeoSiteFormSelectiveSync from './geo_site_form_selective_sync.vue';

export default {
  name: 'GeoSiteForm',
  i18n: {
    saveChanges: __('Save changes'),
    cancel: __('Cancel'),
  },
  components: {
    GlButton,
    GeoSiteFormCore,
    GeoSiteFormSelectiveSync,
    GeoSiteFormCapacities,
  },
  props: {
    site: {
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
      siteData: {
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
    ...mapState(['sitesPath']),
  },
  created() {
    if (this.site) {
      this.siteData = { ...this.site };
    }
  },
  methods: {
    ...mapActions(['saveGeoSite']),
    redirect() {
      visitUrl(this.sitesPath);
    },
    addSyncOption({ key, value }) {
      this.siteData[key].push(value);
    },
    removeSyncOption({ key, index }) {
      this.siteData[key].splice(index, 1);
    },
  },
};
</script>

<template>
  <form>
    <geo-site-form-core
      :site-data="siteData"
      class="gl-pb-4 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid"
    />
    <geo-site-form-selective-sync
      v-if="!siteData.primary"
      class="gl-pb-4 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid"
      :site-data="siteData"
      :selective-sync-types="selectiveSyncTypes"
      :sync-shards-options="syncShardsOptions"
      @addSyncOption="addSyncOption"
      @removeSyncOption="removeSyncOption"
    />
    <geo-site-form-capacities :site-data="siteData" />
    <section
      class="gl-display-flex gl-align-items-center gl-py-5 gl-mt-6 gl-border-t-solid gl-border-t-1 gl-border-gray-100"
    >
      <gl-button
        id="site-save-button"
        data-qa-selector="add_site_button"
        class="gl-mr-3"
        variant="confirm"
        :disabled="formHasError"
        @click="saveGeoSite(siteData)"
        >{{ $options.i18n.saveChanges }}</gl-button
      >
      <gl-button id="site-cancel-button" @click="redirect">{{ $options.i18n.cancel }}</gl-button>
    </section>
  </form>
</template>
