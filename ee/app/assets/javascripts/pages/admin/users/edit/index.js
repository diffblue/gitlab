import initPasswordValidator from 'ee/password/password_validator';
import { pipelineMinutes } from '../pipeline_minutes';

pipelineMinutes();
initPasswordValidator({ allowNoPassword: true });
