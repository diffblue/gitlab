<script>
import { GlTable } from '@gitlab/ui';
import { s__, createDateTimeFormat } from '~/locale';

const dateFormat = createDateTimeFormat({
  dateStyle: 'long',
  timeStyle: 'long',
});

export default {
  components: {
    GlTable,
  },
  props: {
    metadata: {
      required: true,
      type: Object,
    },
  },
  computed: {
    fields() {
      return [
        {
          key: 'item_name',
          thClass: 'hidden',
        },
        {
          key: 'item_data',
          thClass: 'hidden',
        },
      ];
    },
    items() {
      return [
        {
          name: s__('SecureFiles|UUID'),
          data: this.metadata.id,
        },
        {
          name: s__('SecureFiles|Platforms'),
          data: this.metadata.platforms.join(', '),
        },
        {
          name: s__('SecureFiles|Team'),
          data: `${this.metadata.team_name} (${this.metadata.team_id.join(', ')})`,
        },
        {
          name: s__('SecureFiles|App'),
          data: [this.metadata.app_name, '-', this.metadata.app_id].join(' '),
        },
        {
          name: s__('SecureFiles|Certificates'),
          data: this.metadata.certificate_ids.join(', '),
        },
        {
          name: s__('SecureFiles|Expires at'),
          data: dateFormat.format(new Date(this.metadata.expires_at)),
        },
      ];
    },
  },
};
</script>

<template>
  <div>
    <gl-table :items="items" :fields="fields">
      <template #cell(item_name)="{ item }">
        <strong>{{ item.name }}</strong>
      </template>
      <template #cell(item_data)="{ item }">
        {{ item.data }}
      </template>
    </gl-table>
  </div>
</template>
