/* eslint-disable no-new */

import mountComponents from 'ee/registrations/groups/new';
import BindInOut from '~/behaviors/bind_in_out';
import Group from '~/group';
import { trackSaasTrialGroup } from '~/google_tag_manager';
import GroupPathValidator from '~/pages/groups/new/group_path_validator';

mountComponents();
new GroupPathValidator();
BindInOut.initAll();
new Group();
trackSaasTrialGroup();
