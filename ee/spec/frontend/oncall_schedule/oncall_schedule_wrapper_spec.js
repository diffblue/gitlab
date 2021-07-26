import { GlEmptyState, GlLoadingIcon, GlSprintf, GlLink } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import AddScheduleModal from 'ee/oncall_schedules/components/add_edit_schedule_modal.vue';
import OnCallSchedule from 'ee/oncall_schedules/components/oncall_schedule.vue';
import OnCallScheduleWrapper, {
  i18n,
} from 'ee/oncall_schedules/components/oncall_schedules_wrapper.vue';
import getOncallSchedulesWithRotationsQuery from 'ee/oncall_schedules/graphql/queries/get_oncall_schedules.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { preExistingSchedule, newlyCreatedSchedule } from './mocks/apollo_mock';

const localVue = createLocalVue();

describe('On-call schedule wrapper', () => {
  let wrapper;
  const emptyOncallSchedulesSvgPath = 'illustration/path.svg';
  const projectPath = 'group/project';
  const escalationPoliciesPath = 'group/project/-/escalation_policies';

  function mountComponent({ loading, schedules } = {}) {
    const $apollo = {
      queries: {
        schedules: {
          loading,
        },
      },
    };

    wrapper = extendedWrapper(
      shallowMount(OnCallScheduleWrapper, {
        data() {
          return {
            schedules,
          };
        },
        provide: {
          emptyOncallSchedulesSvgPath,
          projectPath,
          escalationPoliciesPath,
        },
        directives: {
          GlTooltip: createMockDirective(),
        },
        mocks: { $apollo },
        stubs: {
          GlSprintf,
        },
      }),
    );
  }

  let getOncallSchedulesQuerySpy;

  function mountComponentWithApollo() {
    const fakeApollo = createMockApollo([
      [getOncallSchedulesWithRotationsQuery, getOncallSchedulesQuerySpy],
    ]);
    localVue.use(VueApollo);

    wrapper = shallowMount(OnCallScheduleWrapper, {
      localVue,
      apolloProvider: fakeApollo,
      data() {
        return {
          schedules: [],
        };
      },
      provide: {
        emptyOncallSchedulesSvgPath,
        projectPath,
        escalationPoliciesPath,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  const findLoader = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findSchedules = () => wrapper.findAllComponents(OnCallSchedule);
  const findTipAlert = () => wrapper.findByTestId('tip-alert');
  const findSuccessAlert = () => wrapper.findByTestId('success-alert');
  const findAlertLink = () => wrapper.findComponent(GlLink);
  const findModal = () => wrapper.findComponent(AddScheduleModal);
  const findAddAdditionalButton = () => wrapper.findByTestId('add-additional-schedules-button');

  it('shows a loader while data is requested', () => {
    mountComponent({ loading: true });
    expect(findLoader().exists()).toBe(true);
  });

  it('shows empty state and passed correct attributes to it when not loading and no schedule', () => {
    mountComponent({ loading: false, schedules: [] });
    const emptyState = findEmptyState();

    expect(emptyState.exists()).toBe(true);
    expect(emptyState.attributes()).toEqual({
      title: i18n.emptyState.title,
      svgpath: emptyOncallSchedulesSvgPath,
      description: i18n.emptyState.description,
    });
  });

  describe('Schedules created', () => {
    beforeEach(() => {
      mountComponent({
        loading: false,
        schedules: [{ name: 'monitor rotation' }, { name: 'monitor rotation 2' }],
      });
    });

    it('renders the schedules when data received', () => {
      expect(findLoader().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
      expect(findSchedules()).toHaveLength(2);
    });

    it('renders an add button with a tooltip for additional schedules', () => {
      const button = findAddAdditionalButton();
      expect(button.exists()).toBe(true);
      const tooltip = getBinding(button.element, 'gl-tooltip');
      expect(tooltip).toBeDefined();
      expect(button.attributes('title')).toBe(i18n.add.tooltip);
    });

    it('shows alert with a tip on new schedule creation', async () => {
      await findModal().vm.$emit('scheduleCreated');
      const alert = findTipAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.props('title')).toBe(i18n.successNotification.title);
      expect(findAlertLink().attributes('href')).toBe(escalationPoliciesPath);
    });

    it("hides tip alert and shows success alert on schedule's rotation update", async () => {
      await findModal().vm.$emit('scheduleCreated');
      expect(findTipAlert().exists()).toBe(true);

      const rotationUpdateMsg = 'Rotation updated';
      findSchedules().at(0).vm.$emit('rotation-updated', rotationUpdateMsg);
      await nextTick();
      expect(findTipAlert().exists()).toBe(false);
      const successAlert = findSuccessAlert();
      expect(successAlert.exists()).toBe(true);
      expect(successAlert.text()).toBe(rotationUpdateMsg);
    });
  });

  describe('Apollo', () => {
    beforeEach(() => {
      getOncallSchedulesQuerySpy = jest.fn().mockResolvedValue({
        data: {
          project: {
            incidentManagementOncallSchedules: {
              nodes: [preExistingSchedule, newlyCreatedSchedule],
            },
          },
        },
      });
    });

    it('should render newly created schedule', async () => {
      mountComponentWithApollo();
      jest.runOnlyPendingTimers();
      await nextTick();
      const schedule = findSchedules().at(1);
      expect(schedule.props('schedule')).toEqual(newlyCreatedSchedule);
    });
  });
});
