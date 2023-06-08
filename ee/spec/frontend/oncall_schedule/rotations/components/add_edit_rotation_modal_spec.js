import { GlAlert, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { cloneDeep } from 'lodash';
import AddEditRotationForm from 'ee/oncall_schedules/components/rotations/components/add_edit_rotation_form.vue';
import AddEditRotationModal, {
  i18n,
} from 'ee/oncall_schedules/components/rotations/components/add_edit_rotation_modal.vue';
import { addRotationModalId } from 'ee/oncall_schedules/constants';
import createOncallScheduleRotationMutation from 'ee/oncall_schedules/graphql/mutations/create_oncall_schedule_rotation.mutation.graphql';
import getOncallSchedulesWithRotationsQuery from 'ee/oncall_schedules/graphql/queries/get_oncall_schedules.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import searchProjectMembersQuery from '~/graphql_shared/queries/project_user_members_search.query.graphql';
import {
  getOncallSchedulesQueryResponse,
  createRotationResponse,
  createRotationResponseWithErrors,
} from '../../mocks/apollo_mock';
import mockRotation from '../../mocks/mock_rotation.json';

jest.mock('~/alert');
jest.mock('~/lib/utils/color_utils');

const schedule =
  getOncallSchedulesQueryResponse.data.project.incidentManagementOncallSchedules.nodes[0];
const projectPath = 'group/project';

describe('AddEditRotationModal', () => {
  let wrapper;
  let mockApollo;
  let userSearchQueryHandler;
  let createRotationHandler;

  const mockHideModal = jest.fn(function hide() {
    this.$emit('hide');
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findForm = () => wrapper.findComponent(AddEditRotationForm);

  const updateRotationForm = (type, value) => {
    return findForm().vm.$emit('update-rotation-form', {
      type,
      value,
    });
  };

  const createComponent = ({
    rotationHandler = jest.fn().mockResolvedValue(createRotationResponse),
    props = {},
  } = {}) => {
    createRotationHandler = rotationHandler;
    Vue.use(VueApollo);

    mockApollo = createMockApollo([
      [
        getOncallSchedulesWithRotationsQuery,
        jest.fn().mockResolvedValue(getOncallSchedulesQueryResponse),
      ],
      [searchProjectMembersQuery, userSearchQueryHandler],
      [createOncallScheduleRotationMutation, createRotationHandler],
    ]);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getOncallSchedulesWithRotationsQuery,
      variables: {
        projectPath,
      },
      data: getOncallSchedulesQueryResponse.data,
    });

    wrapper = shallowMount(AddEditRotationModal, {
      apolloProvider: mockApollo,
      provide: {
        projectPath,
      },
      propsData: {
        modalId: addRotationModalId,
        schedule,
        rotation: mockRotation[0],
        ...props,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            hide: mockHideModal,
          },
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders rotation modal layout', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders correct buttons for modal actions', () => {
    expect(findModal().props('actionCancel').text).toBe(i18n.cancel);
    expect(findModal().props('actionPrimary').text).toBe(i18n.addRotation);
    expect(findModal().props('actionPrimary').attributes).toEqual({
      variant: 'confirm',
      loading: false,
      disabled: true,
    });
  });

  describe('Creating rotation', () => {
    it('shows loading spinner on action button while calling a mutation', async () => {
      updateRotationForm('name', mockRotation[0].name);
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await nextTick();

      expect(findModal().props('actionPrimary').attributes.loading).toBe(true);
    });

    it('emits "rotation-updated" event and with the confirmation message', async () => {
      updateRotationForm('name', mockRotation[0].name);
      expect(wrapper.emitted('rotation-updated')).toBeUndefined();

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await nextTick();
      await waitForPromises();

      const emittedEvents = wrapper.emitted('rotation-updated');
      const emittedMsg = emittedEvents[0][0];

      expect(emittedEvents).toHaveLength(1);
      expect(emittedMsg).toBe(i18n.rotationCreated);
      expect(findModal().props('actionPrimary').attributes.loading).toBe(false);
    });

    it('displays alert if mutation had a recoverable error', async () => {
      createComponent({
        rotationHandler: jest.fn().mockResolvedValue(createRotationResponseWithErrors),
      });
      updateRotationForm('name', mockRotation[0].name);

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await nextTick();
      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toContain('Houston, we have a problem');
      expect(findForm().props('form').name).toBe(mockRotation[0].name);
    });

    it('calls the `searchProjectMembersQuery` query with the search parameter and project path', async () => {
      userSearchQueryHandler = jest.fn().mockResolvedValue();
      createComponent();
      findForm().vm.$emit('filter-participants', 'root');
      await waitForPromises();
      expect(userSearchQueryHandler).toHaveBeenCalledWith({
        search: 'root',
        fullPath: projectPath,
      });
    });

    describe('Validation', () => {
      describe('name', () => {
        it('is valid when name is NOT empty', () => {
          updateRotationForm('name', '');
          expect(findForm().props('validationState').name).toBe(false);
        });

        it('is NOT valid when name is empty', () => {
          updateRotationForm('name', 'Some value');
          expect(findForm().props('validationState').name).toBe(true);
        });
      });

      describe('participants', () => {
        it('is valid when participants array is NOT empty', () => {
          updateRotationForm('participants', ['user1', 'user2']);
          expect(findForm().props('validationState').participants).toBe(true);
        });

        it('is NOT valid when participants array is empty', () => {
          updateRotationForm('participants', []);
          expect(findForm().props('validationState').participants).toBe(false);
        });
      });

      describe('rotationLength', () => {
        it('is valid when length is more than 0', () => {
          updateRotationForm('rotationLength.length', 4);
          expect(findForm().props('validationState').rotationLength).toBe(true);
        });

        it('is valid NOT when length is less than 0', async () => {
          updateRotationForm('rotationLength.length', -4);
          await nextTick();
          expect(findForm().props('validationState').rotationLength).toBe(false);
        });
      });

      describe('startsAt date', () => {
        it('is valid when date is NOT empty', () => {
          updateRotationForm('startsAt.date', new Date('10/12/2021'));
          expect(findForm().props('validationState').startsAt).toBe(true);
        });

        it('is NOT valid when date is empty', () => {
          updateRotationForm('startsAt.date', null);
          expect(findForm().props('validationState').startsAt).toBe(false);
        });
      });

      describe('endsAt date', () => {
        it('is valid when date is empty', () => {
          updateRotationForm('endsAt.date', null);
          expect(findForm().props('validationState').endsAt).toBe(true);
        });

        it('is valid when start date is smaller then end date', () => {
          updateRotationForm('startsAt.date', new Date('9/11/2021'));
          updateRotationForm('endsAt.date', new Date('10/11/2021'));
          expect(findForm().props('validationState').endsAt).toBe(true);
        });

        it('is invalid when start date is larger then end date', () => {
          updateRotationForm('startsAt.date', new Date('11/11/2021'));
          updateRotationForm('endsAt.date', new Date('10/11/2021'));
          expect(findForm().props('validationState').endsAt).toBe(false);
        });

        it('is valid when start and end dates are equal but time is smaller on start date', () => {
          updateRotationForm('startsAt.date', new Date('11/11/2021'));
          updateRotationForm('startsAt.time', 10);
          updateRotationForm('endsAt.date', new Date('11/11/2021'));
          updateRotationForm('endsAt.time', 22);
          expect(findForm().props('validationState').endsAt).toBe(true);
        });

        it('is invalid when start and end dates are equal but time is larger on start date', () => {
          updateRotationForm('startsAt.date', new Date('11/11/2021'));
          updateRotationForm('startsAt.time', 10);
          updateRotationForm('endsAt.date', new Date('11/11/2021'));
          updateRotationForm('endsAt.time', 8);
          expect(findForm().props('validationState').endsAt).toBe(false);
        });
      });

      describe('Toggle primary button state', () => {
        it('should disable primary button when any of the fields is invalid', async () => {
          updateRotationForm('name', 'lalal');
          await nextTick();
          expect(findModal().props('actionPrimary').attributes).toEqual(
            expect.objectContaining({ disabled: true }),
          );
        });

        it('should enable primary button when all fields are valid', async () => {
          updateRotationForm('name', 'Value');
          updateRotationForm('participants', [1, 2, 3]);
          updateRotationForm('startsAt.date', new Date('11/11/2021'));
          updateRotationForm('endsAt.date', new Date('12/10/2021'));
          await nextTick();
          expect(findModal().props('actionPrimary').attributes).toEqual(
            expect.objectContaining({ disabled: false }),
          );
        });
      });
    });
  });

  describe('When editing exisiting rotation', () => {
    beforeEach(async () => {
      await createComponent({ props: { isEditMode: true } });
      await waitForPromises();

      findModal().vm.$emit('show');
    });

    it('should load name correctly', () => {
      expect(findForm().props('form')).toMatchObject({
        name: 'Rotation 242',
      });
    });

    it('should load rotation length correctly', () => {
      expect(findForm().props('form')).toMatchObject({
        rotationLength: {
          length: 2,
          unit: 'WEEKS',
        },
      });
    });

    it('should load participants correctly', () => {
      expect(cloneDeep(findForm().props('form'))).toMatchObject({
        participants: [
          {
            id: 'gid://gitlab/IncidentManagement::OncallParticipant/49',
            username: 'nora.schaden',
            avatarUrl: '/url',
            name: 'nora',
          },
          {
            id: 'gid://gitlab/User/2',
            username: 'racheal.loving',
            avatarUrl: '/url',
            name: 'racheal',
          },
        ],
      });
    });

    it('should load startTime correctly', () => {
      expect(findForm().props('form')).toMatchObject({
        startsAt: {
          date: new Date('2021-01-13T00:00:00.000Z'),
          time: 3,
        },
      });
    });

    it('should load endTime correctly', () => {
      expect(findForm().props('form')).toMatchObject({
        endsAt: {
          date: new Date('2021-03-13T00:00:00.000Z'),
          time: 7,
        },
      });
    });

    it('should load rotation restriction data successfully', () => {
      expect(findForm().props('form')).toMatchObject({
        isRestrictedToTime: true,
        restrictedTo: { startTime: 2, endTime: 10 },
      });
    });
  });
});
