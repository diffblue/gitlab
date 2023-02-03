import { STATUS_OPEN } from '~/issues/constants';

export const isEpicOpen = (state) => state.state === STATUS_OPEN;

export const isUserSignedIn = () => Boolean(gon.current_user_id);
