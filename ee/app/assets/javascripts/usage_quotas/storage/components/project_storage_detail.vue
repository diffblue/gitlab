<script>
import { GlIcon, GlLink, GlSprintf, GlTableLite } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { thWidthClass } from '~/lib/utils/table_utility';
import { sprintf } from '~/locale';
import {
  HELP_LINK_ARIA_LABEL,
  PROJECT_TABLE_LABEL_STORAGE_TYPE,
  PROJECT_TABLE_LABEL_USAGE,
} from '../constants';
import { descendingStorageUsageSort } from '../utils';
import StorageTypeIcon from './storage_type_icon.vue';

export default {
  name: 'ProjectStorageDetail',
  components: {
    GlLink,
    GlIcon,
    GlTableLite,
    GlSprintf,
    StorageTypeIcon,
  },
  props: {
    storageTypes: {
      type: Array,
      required: true,
    },
  },
  computed: {
    sizeSortedStorageTypes() {
      return [...this.storageTypes].sort(descendingStorageUsageSort('value'));
    },
  },
  methods: {
    helpLinkAriaLabel(linkTitle) {
      return sprintf(HELP_LINK_ARIA_LABEL, {
        linkTitle,
      });
    },
  },
  projectTableFields: [
    {
      key: 'storageType',
      label: PROJECT_TABLE_LABEL_STORAGE_TYPE,
      thClass: thWidthClass(90),
    },
    {
      key: 'value',
      label: PROJECT_TABLE_LABEL_USAGE,
      thClass: thWidthClass(10),
      formatter: (value) => {
        return numberToHumanSize(value, 1);
      },
    },
  ],
};
</script>
<template>
  <gl-table-lite :items="sizeSortedStorageTypes" :fields="$options.projectTableFields">
    <template #cell(storageType)="{ item }">
      <div class="gl-display-flex gl-flex-direction-row">
        <storage-type-icon
          :name="item.storageType.id"
          :data-testid="`${item.storageType.id}-icon`"
        />
        <div>
          <p class="gl-font-weight-bold gl-mb-0" :data-testid="`${item.storageType.id}-name`">
            {{ item.storageType.name }}
            <gl-link
              v-if="item.storageType.helpPath"
              :href="item.storageType.helpPath"
              target="_blank"
              :aria-label="helpLinkAriaLabel(item.storageType.name)"
              :data-testid="`${item.storageType.id}-help-link`"
            >
              <gl-icon name="question" :size="12" />
            </gl-link>
          </p>
          <p class="gl-mb-0" :data-testid="`${item.storageType.id}-description`">
            {{ item.storageType.description }}
          </p>
          <p v-if="item.storageType.warningMessage" class="gl-mb-0 gl-font-sm">
            <gl-icon name="warning" :size="12" />
            <gl-sprintf :message="item.storageType.warningMessage">
              <template #warningLink="{ content }">
                <gl-link :href="item.storageType.warningLink" target="_blank" class="gl-font-sm">{{
                  content
                }}</gl-link>
              </template>
            </gl-sprintf>
          </p>
        </div>
      </div>
    </template>
  </gl-table-lite>
</template>
