import { GlLink, GlSkeletonLoader, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { capitalize } from 'lodash';
import StatusDescription from 'ee/vulnerabilities/components/status_description.vue';
import {
  VULNERABILITY_STATE_OBJECTS,
  VULNERABILITY_STATES,
  DISMISSAL_REASONS,
} from 'ee/vulnerabilities/constants';
import UsersMockHelper from 'helpers/user_mock_data_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

const { detected, ...NON_DETECTED_STATE_OBJECTS } = VULNERABILITY_STATE_OBJECTS;
const NON_DETECTED_STATES = Object.keys(NON_DETECTED_STATE_OBJECTS);
const ALL_STATES = Object.keys(VULNERABILITY_STATES);

describe('Vulnerability status description component', () => {
  let wrapper;

  const timeAgo = () => wrapper.findComponent(TimeAgoTooltip);
  const pipelineLink = () => wrapper.findComponent(GlLink);
  const userAvatar = () => wrapper.findComponent(UserAvatarLink);
  const userLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const skeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const statusEl = () => wrapper.find('[data-testid="status"]');

  // Create a date using the passed-in string, or just use the current time if nothing was passed in.
  const createDate = (value) => (value ? new Date(value) : new Date()).toISOString();

  const createWrapper = (props = {}, dismissalReason = true) => {
    const vulnerability = props.vulnerability || { pipeline: {} };
    // Automatically create the ${v.state}_at property if it doesn't exist. Otherwise, every test would need to create
    // it manually for the component to mount properly.
    if (vulnerability.pipeline && vulnerability.state === 'detected') {
      vulnerability.pipeline.createdAt = vulnerability.pipeline.createdAt || createDate();
    } else {
      const propertyName = `${vulnerability.state}At`;
      vulnerability[propertyName] = vulnerability[propertyName] || createDate();
    }

    wrapper = mount(StatusDescription, {
      propsData: { ...props, vulnerability },
      provide: { glFeatures: { dismissalReason } },
    });
  };

  describe('state text', () => {
    // This also tests the dismissed state when no dismissalReason is provided
    it.each(ALL_STATES)('shows the correct string for the vulnerability state "%s"', (state) => {
      createWrapper({ vulnerability: { state, pipeline: {} } });

      expect(statusEl().text()).toBe(`${capitalize(state)} ·`);
    });

    it.each(Object.entries(DISMISSAL_REASONS))(
      'shows the correct string for the dismissal reason "%s"',
      (dismissalReason, translation) => {
        createWrapper({
          vulnerability: {
            state: 'dismissed',
            stateTransitions: [
              {
                dismissalReason,
              },
            ],
            pipeline: {},
          },
        });

        expect(statusEl().text()).toBe(`Dismissed: ${translation} ·`);
      },
    );

    it.each`
      description                          | isStatusBolded
      ${'does not show bolded state text'} | ${false}
      ${'shows bolded state text'}         | ${true}
    `('$description if isStatusBolded is $isStatusBolded', ({ isStatusBolded }) => {
      createWrapper({
        vulnerability: { state: 'detected', pipeline: { createdAt: createDate('2001') } },
        isStatusBolded,
      });

      expect(statusEl().classes('gl-font-weight-bold')).toBe(isStatusBolded);
    });
  });

  // Remove this test once dismissalReason feature flag is on by default
  describe('when the "dismissalReason" feature flag is disabled', () => {
    it('does not show the dismissal reason in the state text', () => {
      createWrapper(
        {
          vulnerability: {
            state: 'dismissed',
            stateTransitions: [
              {
                dismissalReason: 'used_in_tests',
              },
            ],
            pipeline: {},
          },
        },
        false,
      );

      expect(statusEl().text()).toBe('Dismissed ·');
    });
  });

  describe('time ago', () => {
    it('uses the pipeline created date when the vulnerability state is "detected"', () => {
      const pipelineDateString = createDate('2001');
      createWrapper({
        vulnerability: { state: 'detected', pipeline: { createdAt: pipelineDateString } },
      });

      expect(timeAgo().props('time')).toBe(pipelineDateString);
    });

    // The .map() is used to output the correct test name by doubling up the parameter, i.e. 'detected' -> ['detected', 'detected'].
    it.each(NON_DETECTED_STATES.map((x) => [x, x]))(
      'uses the "%s_at" property when the vulnerability state is "%s"',
      (state) => {
        const expectedDate = createDate();
        createWrapper({
          vulnerability: {
            state,
            pipeline: { createdAt: 'pipeline_created_at' },
            [`${state}At`]: expectedDate,
          },
        });

        expect(timeAgo().props('time')).toBe(expectedDate);
      },
    );
  });

  describe('pipeline link', () => {
    it('shows the pipeline link when the vulnerability state is "detected"', () => {
      createWrapper({
        vulnerability: { state: 'detected', pipeline: { url: 'pipeline/url' } },
      });

      expect(pipelineLink().attributes('href')).toBe('pipeline/url');
    });

    it.each(NON_DETECTED_STATES)(
      'does not show the pipeline link when the vulnerability state is "%s"',
      (state) => {
        createWrapper({
          vulnerability: { state, pipeline: { url: 'pipeline/url' } },
        });

        expect(pipelineLink().exists()).toBe(false); // The user avatar should be shown instead, those tests are handled separately.
      },
    );
  });

  describe('user', () => {
    it('shows a loading icon when the user is loading', () => {
      createWrapper({
        vulnerability: { state: 'dismissed' },
        isLoadingUser: true,
        user: UsersMockHelper.createRandomUser(), // Create a user so we can verify that the loading icon and the user is not shown at the same time.
      });

      expect(userLoadingIcon().exists()).toBe(true);
      expect(userAvatar().exists()).toBe(false);
    });

    it('shows the user when it exists and is not loading', () => {
      const user = UsersMockHelper.createRandomUser();
      createWrapper({
        vulnerability: { state: 'resolved' },
        user,
      });

      expect(userLoadingIcon().exists()).toBe(false);
      expect(userAvatar().props()).toMatchObject({
        linkHref: user.web_url,
        imgSrc: user.avatar_url,
        username: user.name,
      });
    });

    it('does not show the user when it does not exist and is not loading', () => {
      createWrapper();

      expect(userLoadingIcon().exists()).toBe(false);
      expect(userAvatar().exists()).toBe(false);
    });
  });

  describe('skeleton loader', () => {
    it('shows a skeleton loader and does not show anything else when the vulnerability is loading', () => {
      createWrapper({ isLoadingVulnerability: true });

      expect(skeletonLoader().exists()).toBe(true);
      expect(timeAgo().exists()).toBe(false);
      expect(pipelineLink().exists()).toBe(false);
    });

    it('hides the skeleton loader and shows everything else when the vulnerability is not loading', () => {
      createWrapper({ vulnerability: { state: 'detected', pipeline: {} } });

      expect(skeletonLoader().exists()).toBe(false);
      expect(timeAgo().exists()).toBe(true);
      expect(pipelineLink().exists()).toBe(true);
    });
  });

  describe('without pipeline data', () => {
    it('does not render any information', () => {
      // mount without a pipeline
      createWrapper({ vulnerability: { state: 'detected', pipeline: null } });

      expect(timeAgo().exists()).toBe(false);
      expect(pipelineLink().exists()).toBe(false);
    });
  });
});
