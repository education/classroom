# frozen_string_literal: true

class AssignmentReposController < ApplicationController
  include OrganizationAuthorization
  include GitHubRepoStatus

  layout false

  def show
    @assignment_repo = AssignmentRepo.includes(:user).includes(:assignment).find_by!(id: params[:id])
  end
end
