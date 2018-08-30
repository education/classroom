# frozen_string_literal: true

class ApplicationController
  def ensure_team_management_flipper_is_enabled
    not_found unless team_management_enabled?
  end

  def ensure_student_identifier_flipper_is_enabled
    not_found unless student_identifier_enabled?
  end

  def ensure_group_import_resiliency_enabled
    not_found unless group_import_resiliency_enabled?
  end

  def student_identifier_enabled?
    logged_in? && current_user.feature_enabled?(:student_identifier)
  end
  helper_method :student_identifier_enabled?

  def team_management_enabled?
    logged_in? && current_user.feature_enabled?(:team_management)
  end
  helper_method :team_management_enabled?

  def import_resiliency_enabled?
    logged_in? && current_user.feature_enabled?(:import_resiliency)
  end
  helper_method :import_resiliency_enabled?

  def group_import_resiliency_enabled?
    logged_in? && current_user.feature_enabled?(:group_import_resiliency)
  end
  helper_method :group_import_resiliency_enabled?

  def download_repositories_enabled?
    logged_in? && current_user.feature_enabled?(:download_repositories)
  end
  helper_method :download_repositories_enabled?
end
