<script>
import { GlTable } from '@gitlab/ui';
import Actions from 'ee/security_configuration/corpus_management/components/columns/actions.vue';
import Name from 'ee/security_configuration/corpus_management/components/columns/name.vue';
import Target from 'ee/security_configuration/corpus_management/components/columns/target.vue';
import { s__ } from '~/locale';
import UserDate from '~/vue_shared/components/user_date.vue';
import { ISO_SHORT_FORMAT } from '~/vue_shared/constants';
import { thWidthClass } from '~/lib/utils/table_utility';

const thClass = 'gl-bg-transparent! gl-border-gray-100! gl-border-b-solid! gl-border-b-1!';

export default {
  components: {
    GlTable,
    Name,
    Target,
    UserDate,
    Actions,
  },
  inject: ['projectFullPath'],
  props: {
    corpuses: {
      type: Array,
      required: true,
    },
  },
  fields: [
    {
      key: 'name',
      label: s__('CorpusManagement|Corpus name'),
      thClass: `${thClass} ${thWidthClass(40)}`,
      tdClass: 'gl-text-truncate gl-max-w-15',
    },
    {
      key: 'target',
      label: s__('CorpusManagement|Target'),
      thClass: `${thClass} ${thWidthClass(20)}`,
      tdClass: 'gl-word-break-word',
    },
    {
      key: 'lastUpdated',
      label: s__('CorpusManagement|Last updated'),
      thClass: `${thClass} ${thWidthClass(15)}`,
    },
    {
      key: 'lastUsed',
      label: s__('CorpusManagement|Last used'),
      thClass: `${thClass} ${thWidthClass(15)}`,
    },
    {
      key: 'actions',
      label: s__('CorpusManagement|Actions'),
      thClass: `${thClass} ${thWidthClass(10)}`,
    },
  ],
  i18n: {
    emptyTable: s__('CorpusManagement|Currently, there are no uploaded or generated corpuses.'),
  },
  methods: {
    onDelete({ package: { id } }) {
      this.$emit('delete', id);
    },
    target(corpus) {
      return corpus.package.pipelines.nodes[0]?.ref;
    },
    lastUpdated(corpus) {
      return corpus.package.updatedAt;
    },
    lastUsed(corpus) {
      return corpus.package.pipelines.nodes[0]?.updatedAt;
    },
  },
  dateFormat: ISO_SHORT_FORMAT,
};
</script>
<template>
  <gl-table :items="corpuses" :fields="$options.fields" show-empty>
    <template #empty>
      {{ $options.i18n.emptyTable }}
    </template>

    <template #cell(name)="{ item }">
      <name :corpus="item" />
    </template>

    <template #cell(target)="{ item }">
      <target :target="target(item)" />
    </template>

    <template #cell(lastUpdated)="{ item }">
      <user-date :date="lastUpdated(item)" :date-format="$options.dateFormat" />
    </template>

    <template #cell(lastUsed)="{ item }">
      <user-date :date="lastUsed(item)" :date-format="$options.dateFormat" />
    </template>

    <template #cell(actions)="{ item }">
      <actions :corpus="item" @delete="onDelete" />
    </template>
  </gl-table>
</template>
