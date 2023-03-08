import produce from 'immer';
import { createAlert } from '~/alert';

import {
  DELETE_SCHEDULE_ERROR,
  UPDATE_SCHEDULE_ERROR,
  UPDATE_ROTATION_ERROR,
  DELETE_ROTATION_ERROR,
} from './error_messages';

const ROTATION_CONNECTION_TYPE = 'IncidentManagementOncallRotationConnection';

const addScheduleToStore = (store, query, { oncallScheduleCreate }, variables) => {
  const schedule = oncallScheduleCreate?.oncallSchedule;
  if (!schedule) {
    return;
  }

  const sourceData = store.readQuery({
    query,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    draftData.project.incidentManagementOncallSchedules.nodes = [
      ...draftData.project.incidentManagementOncallSchedules.nodes,
      {
        ...schedule,
        rotations: { nodes: [], __typename: ROTATION_CONNECTION_TYPE },
      },
    ];
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
};

const deleteScheduleFromStore = (store, query, { oncallScheduleDestroy }, variables) => {
  const schedule = oncallScheduleDestroy?.oncallSchedule;
  if (!schedule) {
    return;
  }

  const sourceData = store.readQuery({
    query,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    draftData.project.incidentManagementOncallSchedules.nodes = draftData.project.incidentManagementOncallSchedules.nodes.filter(
      ({ iid }) => iid !== schedule.iid,
    );
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
};

const updateScheduleFromStore = (store, query, { oncallScheduleUpdate }, variables) => {
  const schedule = oncallScheduleUpdate?.oncallSchedule;
  if (!schedule) {
    return;
  }

  const sourceData = store.readQuery({
    query,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    draftData.project.incidentManagementOncallSchedules.nodes = draftData.project.incidentManagementOncallSchedules.nodes.map(
      (scheduleToUpdate) => {
        return scheduleToUpdate.iid === schedule.iid ? schedule : scheduleToUpdate;
      },
    );
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
};

const updateRotationFromStore = (
  store,
  query,
  { oncallRotationUpdate, scheduleIid },
  variables,
) => {
  const rotation = oncallRotationUpdate?.oncallRotation;
  if (!rotation) {
    return;
  }

  const sourceData = store.readQuery({
    query,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    const scheduleToUpdate = draftData.project.incidentManagementOncallSchedules.nodes.find(
      ({ iid }) => iid === scheduleIid,
    );

    const updatedRotations = scheduleToUpdate.rotations.nodes.map((rotationToUpdate) => {
      return rotationToUpdate.id === rotation.id ? rotation : rotationToUpdate;
    });

    scheduleToUpdate.rotations.nodes = updatedRotations;
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
};

const deleteRotationFromStore = (
  store,
  query,
  { oncallRotationDestroy, scheduleIid },
  variables,
) => {
  const rotation = oncallRotationDestroy?.oncallRotation;
  if (!rotation) {
    return;
  }

  const sourceData = store.readQuery({
    query,
    variables,
  });

  const data = produce(sourceData, (draftData) => {
    const scheduleToUpdate = draftData.project.incidentManagementOncallSchedules.nodes.find(
      ({ iid }) => iid === scheduleIid,
    );

    const updatedRotations = scheduleToUpdate.rotations.nodes.filter(
      ({ id }) => id !== rotation.id,
    );

    scheduleToUpdate.rotations.nodes = updatedRotations;
  });

  store.writeQuery({
    query,
    variables,
    data,
  });
};

const onError = (data, message) => {
  createAlert({ message });
  throw new Error(data.errors);
};

export const hasErrors = ({ errors = [] }) => errors?.length;

export const updateStoreOnScheduleCreate = (store, query, data, variables) => {
  if (!hasErrors(data)) {
    addScheduleToStore(store, query, data, variables);
  }
};

export const updateStoreAfterScheduleDelete = (store, query, data, variables) => {
  if (hasErrors(data)) {
    onError(data, DELETE_SCHEDULE_ERROR);
  } else {
    deleteScheduleFromStore(store, query, data, variables);
  }
};

export const updateStoreAfterScheduleEdit = (store, query, data, variables) => {
  if (hasErrors(data)) {
    onError(data, UPDATE_SCHEDULE_ERROR);
  } else {
    updateScheduleFromStore(store, query, data, variables);
  }
};

export const updateStoreAfterRotationEdit = (store, query, data, variables) => {
  if (hasErrors(data)) {
    onError(data, UPDATE_ROTATION_ERROR);
  } else {
    updateRotationFromStore(store, query, data, variables);
  }
};

export const updateStoreAfterRotationDelete = (store, query, data, variables) => {
  if (hasErrors(data)) {
    onError(data, DELETE_ROTATION_ERROR);
  } else {
    deleteRotationFromStore(store, query, data, variables);
  }
};
