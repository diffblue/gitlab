<script>
import {
  GlTable,
  GlButton,
  GlModalDirective,
  GlTooltipDirective,
  GlIcon,
  GlBadge,
  GlProgressBar,
} from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { formatNumber } from '~/locale';
import {
  TABLE_TEST_IDS_HEADERS,
  I18N_GROUP_COL_LABEL,
  I18N_TABLE_REMOVE_BUTTON_DISABLED,
  I18N_TABLE_REMOVE_BUTTON,
  I18N_OVERVIEW_TABLE_HEADER_GROUP,
  I18N_OVERVIEW_TABLE_HEADER_SUBGROUP,
  TABLE_TEST_IDS_ACTIONS,
  TABLE_TEST_IDS_NAMESPACE,
  DEVOPS_ADOPTION_TABLE_CONFIGURATION,
} from '../constants';
import DevopsAdoptionDeleteModal from './devops_adoption_delete_modal.vue';

const thClass = ['gl-bg-white!', 'gl-text-gray-400'];

const fieldOptions = {
  thClass,
  thAttr: { 'data-testid': TABLE_TEST_IDS_HEADERS },
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
  testids: {
    ACTIONS: TABLE_TEST_IDS_ACTIONS,
    NAMESPACE: TABLE_TEST_IDS_NAMESPACE,
  },
  cols: DEVOPS_ADOPTION_TABLE_CONFIGURATION,
  props: {
    data: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
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
          key: 'name',
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
  },
};
</script>
<template>
  <div>
    <h4>{{ tableHeader }}</h4>
    <gl-table
      :fields="tableHeaderFields"
      :items="formattedData"
      thead-class="gl-border-t-0 gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
      stacked="md"
    >
      <template v-for="header in tableHeaderFields" #[headerSlotName(header.key)]>
        {{ header.label }}
      </template>

      <template #cell(name)="{ item }">
        <div :data-testid="$options.testids.NAMESPACE">
          <span v-if="item.group.latestSnapshot" class="gl-font-weight-bold">{{
            item.group.namespace.fullName
          }}</span>
          <template v-else>
            <span class="gl-text-gray-400">{{ item.group.namespace.fullName }}</span>
            <gl-icon name="hourglass" class="gl-text-gray-400" />
          </template>
          <gl-badge v-if="isCurrentGroup(item.group)" class="gl-ml-1" variant="info">{{
            __('This group')
          }}</gl-badge>
        </div>
      </template>

      <template v-for="col in $options.cols" #[cellSlotName(col.key)]="{ item }">
        <div
          v-if="item.group.latestSnapshot"
          :key="col.key"
          :data-testid="col.testId"
          class="gl-display-flex gl-align-items-center gl-justify-content-end gl-justify-content-md-start"
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
        <span
          v-gl-tooltip.hover="getDeleteButtonTooltipText(item.group)"
          :data-testid="$options.testids.ACTIONS"
        >
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
