# frozen_string_literal: true
class AssignmentInvitationsController < ApplicationController
  layout 'layouts/invitations'

  before_action :check_user_has_identifier, only: [:show]
  before_action :check_user_not_previous_acceptee, only: [:show]

  def accept_invitation
    users_assignment_repo = invitation.redeem_for(current_user)

    if users_assignment_repo.present?
      redirect_to successful_invitation_assignment_invitation_path
    else
      flash[:error] = 'An error has occured, please refresh the page and try again.'
      redirect_to :show
    end
  end

  def show
  end

  def identifier
    not_found if student_identifier || assignment.student_identifier_type.nil?
  end

  def submit_identifier
    student_identifier = invitation.create_student_identifier(current_user, params[:student_identifier])
    if student_identifier.present?
      redirect_to assignment_invitation_path
    else
      flash[:error] = 'An error has occured, please refresh the page and try again.'
      redirect_to identifier_assignment_invitation_path
    end
  end

  def successful_invitation
    not_found unless assignment_repo
  end

  private

  def required_scopes
    Classroom::Scopes::ASSIGNMENT_STUDENT
  end

  def assignment
    @assignment ||= invitation.assignment
  end
  helper_method :assignment

  def assignment_repo
    @assignment_repo ||= AssignmentRepo.find_by(assignment: assignment, user: current_user)
  end
  helper_method :assignment_repo

  def invitation
    @invitation ||= AssignmentInvitation.find_by!(key: params[:id])
  end
  helper_method :invitation

  def organization
    @organization ||= assignment.organization
  end
  helper_method :organization

  def student_identifier
    @student_identifier ||= StudentIdentifier.find_by(user: current_user,
                                                      student_identifier_type: assignment.student_identifier_type)
  end
  helper_method :student_identifier

  def check_user_has_identifier
    return unless assignment.student_identifier_type.present?
    return if student_identifier.present?
    redirect_to identifier_assignment_invitation_path
  end

  def check_user_not_previous_acceptee
    return unless assignment.users.include?(current_user)
    redirect_to successful_invitation_assignment_invitation_path
  end
end
