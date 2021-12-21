<script>
import { GlFormGroup, GlFormInput, GlSprintf, GlLink } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { s__ } from '~/locale';
import {
  VALIDATION_FIELD_KEYS,
  NODE_NAME_MORE_INFO,
  NODE_INTERNAL_URL_MORE_INFO,
} from '../constants';
import { validateName, validateUrl } from '../validations';

export default {
  name: 'GeoNodeFormCore',
  components: {
    GlFormGroup,
    GlFormInput,
    GlSprintf,
    GlLink,
  },
  props: {
    nodeData: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['formErrors']),
    internalUrlDescription() {
      return this.nodeData.primary
        ? s__(
            'AdminGeo|The URL of the primary site that is used internally by the secondary sites.',
          )
        : s__(
            'AdminGeo|The URL of the secondary site that is used internally by the primary site.',
          );
    },
  },
  methods: {
    ...mapActions(['setError']),
    checkName() {
      this.setError({ key: VALIDATION_FIELD_KEYS.NAME, error: validateName(this.nodeData.name) });
    },
    checkUrl() {
      this.setError({ key: VALIDATION_FIELD_KEYS.URL, error: validateUrl(this.nodeData.url) });
    },
  },
  NODE_NAME_MORE_INFO,
  NODE_INTERNAL_URL_MORE_INFO,
};
</script>

<template>
  <section>
    <gl-form-group
      :label="__('Name')"
      label-for="node-name-field"
      :state="Boolean(formErrors.name)"
      :invalid-feedback="formErrors.name"
    >
      <template #description>
        <gl-sprintf
          :message="
            __(
              'Must match with the %{codeStart}geo_node_name%{codeEnd} in %{codeStart}/etc/gitlab/gitlab.rb%{codeEnd}. %{linkStart}Learn more%{linkEnd}',
            )
          "
        >
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
          <template #link="{ content }">
            <gl-link
              :href="$options.NODE_NAME_MORE_INFO"
              target="_blank"
              data-testid="nodeNameMoreInfo"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </template>
      <div
        :class="{ 'is-invalid': Boolean(formErrors.name) }"
        class="gl-display-flex gl-align-items-center"
      >
        <!-- eslint-disable vue/no-mutating-props -->
        <gl-form-input
          id="node-name-field"
          v-model="nodeData.name"
          class="col-sm-6 gl-pr-8!"
          :class="{ 'is-invalid': Boolean(formErrors.name) }"
          data-qa-selector="node_name_field"
          type="text"
          @update="checkName"
        />
        <!-- eslint-enable vue/no-mutating-props -->
        <span class="gl-text-gray-500 m-n5 gl-z-index-2">{{ 255 - nodeData.name.length }}</span>
      </div>
    </gl-form-group>
    <section class="form-row">
      <gl-form-group
        class="col-12 col-sm-6"
        :label="__('URL')"
        label-for="node-url-field"
        :state="Boolean(formErrors.url)"
        :invalid-feedback="formErrors.url"
      >
        <template #description>
          <gl-sprintf
            :message="
              __(
                'Must match with the %{codeStart}external_url%{codeEnd} in %{codeStart}/etc/gitlab/gitlab.rb%{codeEnd}.',
              )
            "
          >
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>
          </gl-sprintf>
        </template>
        <div
          :class="{ 'is-invalid': Boolean(formErrors.url) }"
          class="gl-display-flex gl-align-items-center"
        >
          <!-- eslint-disable vue/no-mutating-props -->
          <gl-form-input
            id="node-url-field"
            v-model="nodeData.url"
            class="gl-pr-8!"
            :class="{ 'is-invalid': Boolean(formErrors.url) }"
            data-qa-selector="node_url_field"
            type="text"
            @update="checkUrl"
          />
          <!-- eslint-enable vue/no-mutating-props -->
          <span class="gl-text-gray-500 m-n5 gl-z-index-2">{{ 255 - nodeData.url.length }}</span>
        </div>
      </gl-form-group>
      <gl-form-group
        class="col-12 col-sm-6"
        :label="__('Internal URL (optional)')"
        label-for="node-internal-url-field"
        :description="internalUrlDescription"
      >
        <template #description>
          <gl-sprintf
            :message="`${internalUrlDescription} ${__('%{linkStart}Learn more.%{linkEnd}')}`"
          >
            <template #link="{ content }">
              <gl-link
                :href="$options.NODE_INTERNAL_URL_MORE_INFO"
                target="_blank"
                data-testid="nodeInternalUrlMoreInfo"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </template>
        <div class="gl-display-flex gl-align-items-center">
          <!-- eslint-disable vue/no-mutating-props -->
          <gl-form-input
            id="node-internal-url-field"
            v-model="nodeData.internalUrl"
            class="gl-pr-8!"
            type="text"
          />
          <!-- eslint-enable vue/no-mutating-props -->
          <span class="gl-text-gray-500 m-n5 gl-z-index-2">{{
            255 - nodeData.internalUrl.length
          }}</span>
        </div>
      </gl-form-group>
    </section>
  </section>
</template>
