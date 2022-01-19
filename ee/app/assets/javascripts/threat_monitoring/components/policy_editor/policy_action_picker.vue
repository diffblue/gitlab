<script>
import { GlForm, GlFormSelect, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { RuleActionTypeAllow } from './network_policy/lib';

export default {
  components: {
    GlForm,
    GlFormSelect,
    GlSprintf,
  },
  data() {
    return { actionType: RuleActionTypeAllow };
  },
  actionTypes: [{ value: RuleActionTypeAllow, text: s__('NetworkPolicies|Allow') }],
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-px-5 gl-pt-5">
    <gl-form inline>
      <gl-sprintf
        :message="
          s__(
            'NetworkPolicies|%{labelStart}Then%{labelEnd} %{action} %{spanStart}the network traffic.%{spanEnd}',
          )
        "
      >
        <template #label="{ content }">
          <label for="actionType" class="text-uppercase gl-font-lg gl-mr-4 gl-mb-5!">{{
            content
          }}</label>
        </template>

        <template #action>
          <gl-form-select
            id="actionType"
            class="gl-mr-4 gl-mb-5!"
            :value="actionType"
            :options="$options.actionTypes"
          />
        </template>

        <template #span="{ content }">
          <span class="gl-mb-5">{{ content }}</span>
        </template>
      </gl-sprintf>
    </gl-form>
  </div>
</template>
