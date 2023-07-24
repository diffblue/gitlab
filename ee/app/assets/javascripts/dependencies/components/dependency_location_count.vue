<script>
import { GlIcon, GlTruncate, GlCollapsibleListbox, GlLink } from '@gitlab/ui';
import { debounce } from 'lodash';
import { s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { filterPathBySearchTerm } from '../store/utils';

const mapItemToListboxFormat = (item, index) => ({
  ...item,
  value: index,
  text: item.location.path,
});

export default {
  name: 'DependencyLocationCount',
  components: {
    GlIcon,
    GlTruncate,
    GlCollapsibleListbox,
    GlLink,
  },
  inject: ['locationsEndpoint'],
  props: {
    locationCount: {
      type: Number,
      required: true,
    },
    componentId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      locations: [],
      searchTerm: '',
    };
  },
  computed: {
    locationText() {
      return sprintf(s__('Dependencies|%{locationCount} locations'), {
        locationCount: Number.isNaN(this.locationCount) ? 0 : this.locationCount,
      });
    },
    availableLocations() {
      return filterPathBySearchTerm(this.locations, this.searchTerm);
    },
  },
  created() {
    this.search = debounce((searchTerm) => {
      this.searchTerm = searchTerm;
      this.fetchData();
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    onHide() {
      this.searchTerm = '';
    },
    onShown() {
      this.search();
    },
    async fetchData() {
      this.loading = true;

      const {
        data: { locations },
      } = await axios.get(this.locationsEndpoint, {
        params: {
          search: this.searchTerm,
          component_id: this.componentId,
        },
      });

      this.loading = false;
      this.locations = locations.map(mapItemToListboxFormat);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :header-text="locationText"
    :items="availableLocations"
    :searching="loading"
    searchable
    @hidden="onHide"
    @search="search"
    @shown="onShown"
  >
    <template #toggle>
      <span class="gl-md-white-space-nowrap gl-text-blue-500">
        <gl-icon name="doc-text" />
        <gl-truncate
          class="gl-display-none gl-md-display-inline-flex"
          position="start"
          :text="locationText"
          with-tooltip
        />
      </span>
    </template>
    <template #list-item="{ item }">
      <div v-if="item">
        <div class="gl-md-white-space-nowrap gl-text-blue-500">
          <gl-link :href="item.location.blob_path" class="gl-hover-text-decoration-none">
            <gl-icon name="doc-text" />
            <gl-truncate position="start" :text="item.location.path" with-tooltip />
          </gl-link>
        </div>
        <gl-truncate :text="item.project.name" class="gl-mt-2 gl-ml-6 gl-text-gray-500" />
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
