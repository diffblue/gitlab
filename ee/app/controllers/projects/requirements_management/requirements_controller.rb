# frozen_string_literal: true

class Projects::RequirementsManagement::RequirementsController < Projects::ApplicationController
  include WorkhorseAuthorization

  EXTENSION_ALLOWLIST = %w[csv].map(&:downcase).freeze

  before_action :authorize_read_requirement!
  before_action :authorize_import_access!, only: [:import_csv, :authorize]

  feature_category :requirements_management
  urgency :high, [:authorize]
  urgency :low, [:index, :import_csv]

  def index
    respond_to do |format|
      format.html
    end
  end

  def import_csv
    file = requirement_params[:file]
    return render json: { message: invalid_file_message } unless file_is_valid?(file)

    result = RequirementsManagement::PrepareImportCsvService.new(project, current_user, file: file).execute

    render json: { message: result.message }
  end

  private

  def requirement_params
    params.permit(:file)
  end

  def authorize_import_access!
    return if can?(current_user, :import_requirements, project)

    if current_user || action_name == 'authorize'
      render_404
    else
      authenticate_user!
    end
  end

  def invalid_file_message
    supported_file_extensions = ".#{EXTENSION_ALLOWLIST.join(', .')}"
    _("The uploaded file was invalid. Supported file extensions are %{extensions}.") % { extensions: supported_file_extensions }
  end

  def uploader_class
    FileUploader
  end

  def maximum_size
    Gitlab::CurrentSettings.max_attachment_size.megabytes
  end

  def file_extension_allowlist
    EXTENSION_ALLOWLIST
  end
end
