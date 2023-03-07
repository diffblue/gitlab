<script>
import {
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlDropdown,
  GlDropdownItem,
  GlDatepicker,
  GlTokenSelector,
  GlAvatar,
  GlAvatarLabeled,
  GlToggle,
  GlCard,
} from '@gitlab/ui';
import {
  LENGTH_ENUM,
  HOURS_IN_DAY,
  CHEVRON_SKIPPING_SHADE_ENUM,
  CHEVRON_SKIPPING_PALETTE_ENUM,
} from 'ee/oncall_schedules/constants';
import { format24HourTimeStringFromInt } from '~/lib/utils/datetime_utility';
import { formatParticipantsForTokenSelector } from 'ee/oncall_schedules/utils/common_utils';
import { s__, __ } from '~/locale';

export const i18n = {
  selectParticipant: s__('OnCallSchedules|Select participant'),
  errorMsg: s__('OnCallSchedules|Failed to add rotation'),
  fields: {
    name: { title: __('Name'), error: s__('OnCallSchedules|Rotation name cannot be empty') },
    participants: {
      title: __('Participants'),
      error: s__('OnCallSchedules|Rotation participants cannot be empty'),
    },
    rotationLength: {
      title: s__('OnCallSchedules|Rotation length'),
      error: s__('OnCallSchedules|Rotation length must be a positive number'),
      description: s__(
        'OnCallSchedules|Please note, rotations with shifts that are less than four hours are currently not supported in the weekly view.',
      ),
    },
    startsAt: {
      title: __('Starts on'),
      error: s__('OnCallSchedules|Rotation start date cannot be empty'),
    },
    endsAt: {
      enableToggle: s__('OnCallSchedules|Enable end date'),
      title: __('Ends on'),
      error: s__('OnCallSchedules|Rotation end date/time must come after start date/time'),
    },
    restrictToTime: {
      enableToggle: s__('OnCallSchedules|Restrict to time intervals'),
      title: s__('OnCallSchedules|For this rotation, on-call will be:'),
    },
  },
};

export default {
  i18n,
  HOURS_IN_DAY,
  tokenColorPalette: {
    shade: CHEVRON_SKIPPING_SHADE_ENUM,
    palette: CHEVRON_SKIPPING_PALETTE_ENUM,
  },
  LENGTH_ENUM,
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlDropdown,
    GlDropdownItem,
    GlDatepicker,
    GlTokenSelector,
    GlAvatar,
    GlAvatarLabeled,
    GlToggle,
    GlCard,
  },
  inject: ['projectPath'],
  props: {
    form: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    validationState: {
      type: Object,
      required: true,
    },
    participants: {
      type: Array,
      required: true,
    },
    schedule: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    formParticipantsWithTokenStyles() {
      return formatParticipantsForTokenSelector(this.form.participants);
    },
  },
  methods: {
    format24HourTimeStringFromInt,
  },
};
</script>

<template>
  <gl-form @submit.prevent="createRotation">
    <div class="w-75 gl-xs-w-full!">
      <gl-form-group
        :label="$options.i18n.fields.name.title"
        label-size="sm"
        label-for="rotation-name"
        :invalid-feedback="$options.i18n.fields.name.error"
        :state="validationState.name"
      >
        <gl-form-input
          id="rotation-name"
          data-qa-selector="rotation_name_field"
          :value="form.name"
          @change="$emit('update-rotation-form', { type: 'name', value: $event })"
        />
      </gl-form-group>

      <gl-form-group
        :label="$options.i18n.fields.participants.title"
        label-size="sm"
        label-for="rotation-participants"
        :invalid-feedback="$options.i18n.fields.participants.error"
        :state="validationState.participants"
      >
        <gl-token-selector
          :selected-tokens="formParticipantsWithTokenStyles"
          :dropdown-items="participants"
          :loading="isLoading"
          @text-input="$emit('filter-participants', $event)"
          @blur="$emit('update-rotation-form', { type: 'participants', value: form.participants })"
          @input="$emit('update-rotation-form', { type: 'participants', value: $event })"
        >
          <template #token-content="{ token }">
            <gl-avatar v-if="token.avatarUrl" :src="token.avatarUrl" :size="16" />
            {{ token.name }}
          </template>
          <template #dropdown-item-content="{ dropdownItem }">
            <gl-avatar-labeled
              :src="dropdownItem.avatarUrl"
              :size="32"
              :label="dropdownItem.name"
              :sub-label="dropdownItem.username"
            />
          </template>
        </gl-token-selector>
      </gl-form-group>

      <gl-form-group
        :label="$options.i18n.fields.rotationLength.title"
        :description="$options.i18n.fields.rotationLength.description"
        label-size="sm"
        label-for="rotation-length"
        :invalid-feedback="$options.i18n.fields.rotationLength.error"
        :state="validationState.rotationLength"
      >
        <div class="gl-display-flex">
          <gl-form-input
            id="rotation-length"
            type="number"
            class="gl-w-12 gl-mr-3"
            min="1"
            :value="form.rotationLength.length"
            @input="$emit('update-rotation-form', { type: 'rotationLength.length', value: $event })"
          />
          <gl-dropdown :text="form.rotationLength.unit.toLowerCase()">
            <gl-dropdown-item
              v-for="unit in $options.LENGTH_ENUM"
              :key="unit"
              :is-checked="form.rotationLength.unit === unit"
              is-check-item
              @click="$emit('update-rotation-form', { type: 'rotationLength.unit', value: unit })"
            >
              {{ unit.toLowerCase() }}
            </gl-dropdown-item>
          </gl-dropdown>
        </div>
      </gl-form-group>

      <gl-form-group
        :label="$options.i18n.fields.startsAt.title"
        label-size="sm"
        :invalid-feedback="$options.i18n.fields.startsAt.error"
        :state="validationState.startsAt"
      >
        <div class="gl-display-flex gl-align-items-center">
          <gl-datepicker
            class="gl-mr-3"
            :value="form.startsAt.date"
            @input="$emit('update-rotation-form', { type: 'startsAt.date', value: $event })"
          >
            <template #default="{ formattedDate }">
              <gl-form-input
                class="gl-w-full"
                data-qa-selector="state_date_field"
                :value="formattedDate"
                :placeholder="__(`YYYY-MM-DD`)"
              />
            </template>
          </gl-datepicker>
          <span> {{ __('at') }} </span>
          <gl-dropdown
            data-testid="rotation-start-time"
            :text="format24HourTimeStringFromInt(form.startsAt.time)"
            class="gl-px-3"
          >
            <gl-dropdown-item
              v-for="(_, time) in $options.HOURS_IN_DAY"
              :key="time"
              :is-checked="form.startsAt.time === time"
              is-check-item
              @click="$emit('update-rotation-form', { type: 'startsAt.time', value: time })"
            >
              <span class="gl-white-space-nowrap"> {{ format24HourTimeStringFromInt(time) }}</span>
            </gl-dropdown-item>
          </gl-dropdown>
          <span> {{ schedule.timezone }} </span>
        </div>
      </gl-form-group>
    </div>
    <div class="gl-display-inline-block">
      <gl-toggle
        :value="form.isEndDateEnabled"
        :label="$options.i18n.fields.endsAt.enableToggle"
        label-position="left"
        class="gl-mb-5"
        @change="
          $emit('update-rotation-form', { type: 'isEndDateEnabled', value: !form.isEndDateEnabled })
        "
      />

      <gl-card
        v-if="form.isEndDateEnabled"
        data-testid="rotation-ends-on"
        class="gl-border-gray-400 gl-bg-gray-10"
      >
        <gl-form-group
          :label="$options.i18n.fields.endsAt.title"
          label-size="sm"
          :state="validationState.endsAt"
          :invalid-feedback="$options.i18n.fields.endsAt.error"
          class="gl-mb-0"
        >
          <div class="gl-display-flex gl-align-items-center">
            <gl-datepicker
              class="gl-mr-3"
              :value="form.endsAt.date"
              @input="$emit('update-rotation-form', { type: 'endsAt.date', value: $event })"
            >
              <template #default="{ formattedDate }">
                <gl-form-input
                  class="gl-w-full"
                  :value="formattedDate"
                  :placeholder="__(`YYYY-MM-DD`)"
                />
              </template>
            </gl-datepicker>
            <span> {{ __('at') }} </span>
            <gl-dropdown
              data-testid="rotation-end-time"
              :text="format24HourTimeStringFromInt(form.endsAt.time)"
              class="gl-px-3"
            >
              <gl-dropdown-item
                v-for="(_, time) in $options.HOURS_IN_DAY"
                :key="time"
                :is-checked="form.endsAt.time === time"
                is-check-item
                @click="$emit('update-rotation-form', { type: 'endsAt.time', value: time })"
              >
                <span class="gl-white-space-nowrap">
                  {{ format24HourTimeStringFromInt(time) }}</span
                >
              </gl-dropdown-item>
            </gl-dropdown>
            <span>{{ schedule.timezone }}</span>
          </div>
        </gl-form-group>
      </gl-card>

      <gl-toggle
        :value="form.isRestrictedToTime"
        data-testid="restricted-to-toggle"
        :label="$options.i18n.fields.restrictToTime.enableToggle"
        label-position="left"
        class="gl-mt-5"
        @change="
          $emit('update-rotation-form', {
            type: 'isRestrictedToTime',
            value: !form.isRestrictedToTime,
          })
        "
      />

      <gl-card
        v-if="form.isRestrictedToTime"
        data-testid="restricted-to-time"
        class="gl-mt-5 gl-border-gray-400 gl-bg-gray-10"
      >
        <gl-form-group
          :label="$options.i18n.fields.restrictToTime.title"
          label-size="sm"
          :invalid-feedback="$options.i18n.fields.endsAt.error"
          class="gl-mb-0"
        >
          <div class="gl-display-flex gl-align-items-center">
            <span> {{ __('From') }} </span>
            <gl-dropdown
              data-testid="restricted-from"
              :text="format24HourTimeStringFromInt(form.restrictedTo.startTime)"
              class="gl-px-3"
            >
              <gl-dropdown-item
                v-for="(_, time) in $options.HOURS_IN_DAY"
                :key="time"
                :is-checked="form.restrictedTo.startTime === time"
                is-check-item
                @click="
                  $emit('update-rotation-form', { type: 'restrictedTo.startTime', value: time })
                "
              >
                <span class="gl-white-space-nowrap">
                  {{ format24HourTimeStringFromInt(time) }}</span
                >
              </gl-dropdown-item>
            </gl-dropdown>
            <span> {{ __('To') }} </span>
            <gl-dropdown
              data-testid="restricted-to"
              :text="format24HourTimeStringFromInt(form.restrictedTo.endTime)"
              class="gl-px-3"
            >
              <gl-dropdown-item
                v-for="(_, time) in $options.HOURS_IN_DAY"
                :key="time"
                :is-checked="form.restrictedTo.endTime === time"
                is-check-item
                @click="
                  $emit('update-rotation-form', { type: 'restrictedTo.endTime', value: time })
                "
              >
                <span class="gl-white-space-nowrap">
                  {{ format24HourTimeStringFromInt(time) }}</span
                >
              </gl-dropdown-item>
            </gl-dropdown>
            <span>{{ schedule.timezone }} </span>
          </div>
        </gl-form-group>
      </gl-card>
    </div>
  </gl-form>
</template>
