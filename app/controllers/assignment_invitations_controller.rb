# frozen_string_literal: true

class AssignmentInvitationsController < ApplicationController
  include InvitationsControllerMethods

  before_action :check_user_not_previous_acceptee, only: [:show]

  def accept
    create_submission do
      redirect_to success_assignment_invitation_path
    end
  end

  def show; end

  private

  def ensure_submission_repository_exists
    return not_found unless current_submission
    return if current_submission
              .github_repository
              .present?(headers: GitHub::APIHeaders.no_cache_no_store)

    current_submission.destroy
    remove_instance_variable(:@current_submission)

    create_submission
  end

  def check_user_not_previous_acceptee
    return if current_submission.nil?
    redirect_to success_assignment_invitation_path
  end

  def create_submission
    result = current_invitation.redeem_for(current_user)

    if result.success?
      yield if block_given?
    else
      flash[:error] = result.error
      redirect_to assignment_invitation_path(current_invitation)
    end
  end

  def current_submission
    @current_submission ||= AssignmentRepo.find_by(assignment: current_assignment, user: current_user)
  end

  def current_invitation
    @current_invitation ||= AssignmentInvitation.find_by!(key: params[:id])
  end

  def required_scopes
    GitHubClassroom::Scopes::ASSIGNMENT_STUDENT
  end
end
