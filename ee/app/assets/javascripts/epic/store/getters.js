import { statusType } from '../constants';

export const isEpicOpen = (state) => state.state === statusType.open;

export const isUserSignedIn = () => Boolean(gon.current_user_id);
