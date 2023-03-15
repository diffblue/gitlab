<script>
import { debounce } from 'lodash';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, n__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import Api from 'ee/api';
import { i18n } from './constants';

export default {
  i18n,
  components: {
    GlCollapsibleListbox,
  },
  props: {
    providerElement: {
      type: HTMLSelectElement,
      required: true,
    },
  },
  data() {
    return {
      alert: null,
      groups: [],
      searching: false,
      selected: '',
    };
  },
  computed: {
    debouncedSearch() {
      return debounce(this.search, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    },
    searchSummarySrText() {
      return n__(`%d group found`, '%d groups found', this.groups.length);
    },
    toggleText() {
      return this.selected || this.$options.i18n.placeholder;
    },
  },
  mounted() {
    this.providerElement.addEventListener('change', this.onProvideElementChange);
    this.search();
  },
  destroy() {
    this.providerElement.removeEventListener('change', this.onProvideElementChange);
  },
  methods: {
    handleSelect(selected) {
      this.selected = selected;
    },
    onProvideElementChange() {
      this.selected = '';
      this.search();
    },
    async search(query = '') {
      this.alert?.dismiss();
      this.groups = [];
      this.searching = true;
      const provider = this.providerElement?.value;
      try {
        const newGroups = await Api.ldapGroups(query, provider, (groups) => groups);
        this.groups = newGroups.map((g) => ({ ...g, text: g.cn, value: g.cn }));
      } catch {
        this.alert = createAlert({
          message: __('There was an error retrieving LDAP groups. Please try again.'),
        });
      } finally {
        this.searching = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-collapsible-listbox
      :items="groups"
      :no-results-text="$options.i18n.noResultsText"
      searchable
      :searching="searching"
      :toggle-text="toggleText"
      @search="debouncedSearch"
      @select="handleSelect"
    >
      <template #search-summary-sr-only>
        {{ searchSummarySrText }}
      </template>
    </gl-collapsible-listbox>
    <input id="ldap_group_link_cn" name="ldap_group_link[cn]" :value="selected" type="hidden" />
  </div>
</template>
