<script>
import {
  GlTable,
  GlButton,
  GlModalDirective,
  GlTooltipDirective,
  GlIcon,
  GlBadge,
  GlProgressBar,
  GlLink,
} from '@gitlab/ui';
import { uniqueId } from 'lodash';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { formatNumber } from '~/locale';
import {
  I18N_GROUP_COL_LABEL,
  I18N_TABLE_REMOVE_BUTTON_DISABLED,
  I18N_TABLE_REMOVE_BUTTON,
  I18N_OVERVIEW_TABLE_HEADER_GROUP,
  I18N_OVERVIEW_TABLE_HEADER_SUBGROUP,
  DEVOPS_ADOPTION_TABLE_CONFIGURATION,
  OVERVIEW_TABLE_SORT_BY_STORAGE_KEY,
  OVERVIEW_TABLE_SORT_DESC_STORAGE_KEY,
  OVERVIEW_TABLE_NAME_KEY,
} from '../constants';
import { getGroupAdoptionPath } from '../utils/helpers';
import DevopsAdoptionDeleteModal from './devops_adoption_delete_modal.vue';

const thClass = ['gl-bg-white!', 'gl-text-gray-400'];

const formatter = (value, key, item) => {
  if (key === OVERVIEW_TABLE_NAME_KEY) {
    return item.group?.namespace?.fullName;
  } else if (item.adoption[key]) return item.adoption[key].adopted;

  return 0;
};

const fieldOptions = {
  thClass,
  thAttr: { 'data-testid': 'headers' },
  sortable: true,
  sortByFormatted: true,
  formatter,
};

export default {
  name: 'DevopsAdoptionOverviewTable',
  components: {
    GlTable,
    GlButton,
    GlIcon,
    GlBadge,
    GlProgressBar,
    DevopsAdoptionDeleteModal,
    LocalStorageSync,
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
  cols: DEVOPS_ADOPTION_TABLE_CONFIGURATION,
  sortByStorageKey: OVERVIEW_TABLE_SORT_BY_STORAGE_KEY,
  sortDescStorageKey: OVERVIEW_TABLE_SORT_DESC_STORAGE_KEY,
  props: {
    data: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      sortBy: OVERVIEW_TABLE_NAME_KEY,
      sortDesc: false,
      selectedNamespace: null,
      deleteModalId: uniqueId('delete-modal-'),
    };
  },
  computed: {
    tableHeader() {
      return this.groupGid ? I18N_OVERVIEW_TABLE_HEADER_SUBGROUP : I18N_OVERVIEW_TABLE_HEADER_GROUP;
    },
    tableHeaderFields() {
      return [
        {
          key: OVERVIEW_TABLE_NAME_KEY,
          label: I18N_GROUP_COL_LABEL,
          ...fieldOptions,
          thClass: ['gl-w-grid-size-30', ...thClass],
          tdClass: 'header-cell da-table-mobile-header',
        },
        ...DEVOPS_ADOPTION_TABLE_CONFIGURATION.map((item) => ({
          ...item,
          ...fieldOptions,
          label: item.title,
          tdClass: 'da-table-mobile-header',
        })),
        {
          key: 'actions',
          tdClass: 'actions-cell',
          ...fieldOptions,
          sortable: false,
        },
      ];
    },
    formattedData() {
      return this.data.nodes.map((group) => ({
        group,
        adoption: DEVOPS_ADOPTION_TABLE_CONFIGURATION.map((item) => {
          const total = item.cols.length;
          const adopted = item.cols.filter(
            (col) => group.latestSnapshot && Boolean(group.latestSnapshot[col.key]),
          ).length;
          const ratio = total ? adopted / total : 1;

          return {
            [item.key]: {
              total,
              adopted,
              percent: formatNumber(ratio, { style: 'percent' }),
            },
          };
        }).reduce((values, formatted) => ({ ...values, ...formatted }), {}),
      }));
    },
  },
  methods: {
    setSelectedNamespace(namespace) {
      this.selectedNamespace = namespace;
    },
    isCurrentGroup(item) {
      return item.namespace?.id === this.groupGid;
    },
    getDeleteButtonTooltipText(item) {
      return this.isCurrentGroup(item)
        ? I18N_TABLE_REMOVE_BUTTON_DISABLED
        : I18N_TABLE_REMOVE_BUTTON;
    },
    headerSlotName(key) {
      return `head(${key})`;
    },
    cellSlotName(key) {
      return `cell(${key})`;
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
    <h4>{{ tableHeader }}</h4>
    <gl-table
      :fields="tableHeaderFields"
      :items="formattedData"
      thead-class="gl-border-t-0 gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
      stacked="md"
      :sort-by.sync="sortBy"
      :sort-desc.sync="sortDesc"
    >
      <template v-for="header in tableHeaderFields" #[headerSlotName(header.key)]>
        {{ header.label }}
      </template>

      <template #cell(name)="{ item }">
        <div data-testid="namespace">
          <template v-if="item.group.latestSnapshot">
            <template v-if="isCurrentGroup(item.group)">
              <span class="gl-text-gray-500 gl-font-weight-bold">{{
                item.group.namespace.fullName
              }}</span>
              <gl-badge class="gl-ml-1" variant="info">{{ __('This group') }}</gl-badge>
            </template>
            <gl-link
              v-else
              :href="getGroupAdoptionPath(item.group.namespace.fullPath)"
              class="gl-text-gray-500 gl-font-weight-bold"
            >
              {{ item.group.namespace.fullName }}
            </gl-link>
          </template>
          <template v-else>
            <span class="gl-text-gray-400">{{ item.group.namespace.fullName }}</span>
            <gl-icon name="hourglass" class="gl-text-gray-400" />
          </template>
        </div>
      </template>

      <template v-for="col in $options.cols" #[cellSlotName(col.key)]="{ item }">
        <div
          v-if="item.group.latestSnapshot"
          :key="col.key"
          :data-testid="col.testId"
          class="gl-display-flex gl-align-items-center gl-justify-content-end gl-md-justify-content-start"
        >
          <span class="gl-w-7 gl-mr-3">{{ item.adoption[col.key].percent }}</span>
          <gl-progress-bar
            :value="item.adoption[col.key].adopted"
            :max="item.adoption[col.key].total"
            class="gl-w-half"
            :variant="col.variant"
          />
        </div>
      </template>

      <template #cell(actions)="{ item }">
        <span v-gl-tooltip.hover="getDeleteButtonTooltipText(item.group)" data-testid="actions">
          <gl-button
            v-gl-modal="deleteModalId"
            :disabled="isCurrentGroup(item.group)"
            category="tertiary"
            icon="remove"
            :aria-label="getDeleteButtonTooltipText(item.group)"
            @click="setSelectedNamespace(item.group)"
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
