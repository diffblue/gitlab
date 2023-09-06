<script>
import { GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ANY_COMMIT, ANY_UNSIGNED_COMMIT, SCAN_RESULT_BRANCH_TYPE_OPTIONS } from '../constants';
import SectionLayout from '../section_layout.vue';
import PolicyRuleBranchSelection from './policy_rule_branch_selection.vue';
import ScanTypeSelect from './base_layout/scan_type_select.vue';
import { getDefaultRule } from './lib';

const COMMIT_LISTBOX_ITEMS = [
  {
    value: ANY_COMMIT,
    text: s__('ScanResultPolicy|any commits'),
  },
  {
    value: ANY_UNSIGNED_COMMIT,
    text: s__('ScanResultPolicy|any unsigned commits'),
  },
];

export default {
  COMMIT_LISTBOX_ITEMS,
  i18n: {
    anyMergeRequestRuleCopy: s__(
      'ScanResultPolicy|When %{scanType} in an open that targets %{branches} with %{commitType}',
    ),
  },
  name: 'AnyMergeRequestRuleBuilder',
  components: {
    ScanTypeSelect,
    SectionLayout,
    GlCollapsibleListbox,
    GlSprintf,
    PolicyRuleBranchSelection,
  },
  inject: ['namespaceType'],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  computed: {
    branchTypes() {
      return SCAN_RESULT_BRANCH_TYPE_OPTIONS(this.namespaceType);
    },
    selectedCommitType() {
      return this.initRule.commits || ANY_COMMIT;
    },
  },
  methods: {
    setBranchType(value) {
      this.$emit('changed', value);
    },
    setScanType(value) {
      const rule = getDefaultRule(value);
      this.$emit('set-scan-type', rule);
    },
    setCommitType(type) {
      this.triggerChanged({ commits: type });
    },
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
  },
};
</script>

<template>
  <section-layout :type="initRule.type" :show-remove-button="false">
    <template #content>
      <section-layout class="gl-bg-white!" :type="initRule.type" @remove="$emit('remove')">
        <template #content>
          <gl-sprintf :message="$options.i18n.anyMergeRequestRuleCopy">
            <template #scanType>
              <scan-type-select :scan-type="initRule.type" @select="setScanType" />
            </template>

            <template #branches>
              <policy-rule-branch-selection
                :init-rule="initRule"
                :branch-types="branchTypes"
                @changed="triggerChanged"
                @set-branch-type="setBranchType"
              />
            </template>

            <template #commitType>
              <gl-collapsible-listbox
                data-testid="commits-type"
                :items="$options.COMMIT_LISTBOX_ITEMS"
                :selected="selectedCommitType"
                @select="setCommitType"
              />
            </template>
          </gl-sprintf>
        </template>
      </section-layout>
    </template>
  </section-layout>
</template>
