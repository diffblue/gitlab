<script>
import {
  GlTable,
  GlButton,
  GlModalDirective,
  GlTooltipDirective,
  GlIcon,
  GlBadge,
  GlLink,
} from '@gitlab/ui';
import { uniqueId } from 'lodash';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  TABLE_SORT_BY_STORAGE_KEY,
  TABLE_SORT_DESC_STORAGE_KEY,
  I18N_TABLE_REMOVE_BUTTON,
  I18N_TABLE_REMOVE_BUTTON_DISABLED,
  I18N_GROUP_COL_LABEL,
} from '../constants';
import { getGroupAdoptionPath } from '../utils/helpers';
import DevopsAdoptionDeleteModal from './devops_adoption_delete_modal.vue';
import DevopsAdoptionTableCellFlag from './devops_adoption_table_cell_flag.vue';

const NAME_HEADER = 'name';

const formatter = (value, key, item) => {
  if (key === NAME_HEADER) {
    return item.namespace?.fullName;
  }

  if (item.latestSnapshot && item.latestSnapshot[key] === false) {
    return 1;
  } else if (item.latestSnapshot && item.latestSnapshot[key]) {
    return 2;
  }

  return 0;
};

const thClass = ['gl-bg-white!', 'gl-text-gray-400'];

const fieldOptions = {
  thClass,
  thAttr: { 'data-testid': 'headers' },
  formatter,
  sortable: true,
  sortByFormatted: true,
};

export default {
  name: 'DevopsAdoptionTable',
  components: {
    GlTable,
    DevopsAdoptionTableCellFlag,
    GlButton,
    LocalStorageSync,
    DevopsAdoptionDeleteModal,
    GlIcon,
    GlBadge,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  inject: {
    groupGid: {
      default: null,
    },
  },
  i18n: {
    removeButtonDisabled: I18N_TABLE_REMOVE_BUTTON_DISABLED,
    removeButton: I18N_TABLE_REMOVE_BUTTON,
  },
  sortByStorageKey: TABLE_SORT_BY_STORAGE_KEY,
  sortDescStorageKey: TABLE_SORT_DESC_STORAGE_KEY,
  props: {
    enabledNamespaces: {
      type: Array,
      required: true,
    },
    cols: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      sortBy: NAME_HEADER,
      sortDesc: false,
      selectedNamespace: null,
      deleteModalId: uniqueId('delete-modal-'),
    };
  },
  computed: {
    tableHeaderFields() {
      return [
        {
          key: 'name',
          label: I18N_GROUP_COL_LABEL,
          ...fieldOptions,
          thClass: ['gl-w-grid-size-30', ...thClass],
        },
        ...this.cols.map((item) => ({
          ...item,
          ...fieldOptions,
        })),
        {
          key: 'actions',
          tdClass: 'actions-cell',
          ...fieldOptions,
          sortable: false,
        },
      ];
    },
  },
  methods: {
    setSelectedNamespace(namespace) {
      this.selectedNamespace = namespace;
    },
    headerSlotName(key) {
      return `head(${key})`;
    },
    cellSlotName(key) {
      return `cell(${key})`;
    },
    isCurrentGroup(item) {
      return item.namespace?.id === this.groupGid;
    },
    getDeleteButtonTooltipText(item) {
      return this.isCurrentGroup(item)
        ? this.$options.i18n.removeButtonDisabled
        : this.$options.i18n.removeButton;
    },
    getGroupAdoptionPath(fullPath) {
      return getGroupAdoptionPath(fullPath);
    },
  },
};
</script>
<template>
  <div>
    <local-storage-sync v-model="sortBy" :storage-key="$options.sortByStorageKey" />
    <local-storage-sync v-model="sortDesc" :storage-key="$options.sortDescStorageKey" />
    <gl-table
      :fields="tableHeaderFields"
      :items="enabledNamespaces"
      :sort-by.sync="sortBy"
      :sort-desc.sync="sortDesc"
      thead-class="gl-border-t-0 gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
      stacked="sm"
    >
      <template v-for="header in tableHeaderFields" #[headerSlotName(header.key)]>
        <div :key="header.key" class="gl-display-flex gl-align-items-center">
          <span>{{ header.label }}</span>
          <gl-icon
            v-if="header.tooltip"
            v-gl-tooltip.hover="header.tooltip"
            name="information-o"
            class="gl-text-gray-200 gl-ml-1"
            :size="14"
          />
        </div>
      </template>

      <template #cell(name)="{ item }">
        <div data-testid="namespace">
          <template v-if="item.latestSnapshot">
            <template v-if="isCurrentGroup(item)">
              <span class="gl-text-gray-500 gl-font-weight-bold">{{
                item.namespace.fullName
              }}</span>
              <gl-badge class="gl-ml-1" variant="info">{{ __('This group') }}</gl-badge>
            </template>
            <gl-link
              v-else
              :href="getGroupAdoptionPath(item.namespace.fullPath)"
              class="gl-text-gray-500 gl-font-weight-bold"
            >
              {{ item.namespace.fullName }}
            </gl-link>
          </template>
          <template v-else>
            <span class="gl-text-gray-400">{{ item.namespace.fullName }}</span>
            <gl-icon name="hourglass" class="gl-text-gray-400" />
          </template>
        </div>
      </template>

      <template v-for="col in cols" #[cellSlotName(col.key)]="{ item }">
        <devops-adoption-table-cell-flag
          v-if="item.latestSnapshot"
          :key="col.key"
          :data-testid="col.testId"
          :enabled="Boolean(item.latestSnapshot[col.key])"
        />
      </template>

      <template #cell(actions)="{ item }">
        <span v-gl-tooltip.hover="getDeleteButtonTooltipText(item)" data-testid="actions">
          <gl-button
            v-gl-modal="deleteModalId"
            :disabled="isCurrentGroup(item)"
            category="tertiary"
            icon="remove"
            :aria-label="$options.i18n.removeButton"
            data-testid="select-namespace"
            @click="setSelectedNamespace(item)"
          />
        </span>
      </template>
    </gl-table>
    <devops-adoption-delete-modal
      v-if="selectedNamespace"
      :modal-id="deleteModalId"
      :namespace="selectedNamespace"
      @enabledNamespacesRemoved="$emit('enabledNamespacesRemoved', $event)"
      @trackModalOpenState="$emit('trackModalOpenState', $event)"
    />
  </div>
</template>
