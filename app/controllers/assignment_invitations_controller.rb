# frozen_string_literal: true

class AssignmentInvitationsController < ApplicationController
  class InvalidStatusForRouteError < StandardError; end

  include InvitationsControllerMethods
  include RepoSetup

  before_action :route_based_on_status, only: %i[show setupv2 success]
  before_action :check_user_not_previous_acceptee, :check_should_redirect_to_roster_page, only: :show
  before_action :ensure_submission_repository_exists, only: :success
  before_action :ensure_import_resiliency_enabled, only: %i[create_repo progress]

  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def accept
    if import_resiliency_enabled?
      result = current_invitation.redeem_for(current_user, import_resiliency: import_resiliency_enabled?)
      case result.status
      when :success
        GitHubClassroom.statsd.increment("v2_exercise_invitation.accept")
      when :pending
        GitHubClassroom.statsd.increment("v2_exercise_invitation.accept")
      when :error
        GitHubClassroom.statsd.increment("v2_exercise_invitation.fail")
        current_invitation_status.errored_creating_repo!
        flash[:error] = result.error
      end
      route_based_on_status
    else
      create_submission do
        GitHubClassroom.statsd.increment("exercise_invitation.accept")
        redirect_to success_assignment_invitation_path
      end
    end
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize

  def setupv2
    not_found unless import_resiliency_enabled?
  end

  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  def create_repo
    job_started = false
    if current_invitation_status.accepted? || current_invitation_status.errored?
      assignment_repo = AssignmentRepo.find_by(assignment: current_assignment, user: current_user)
      assignment_repo&.destroy if assignment_repo&.github_repository&.empty?
      if current_invitation_status.errored_creating_repo?
        GitHubClassroom.statsd.increment("v2_exercise_repo.create.retry")
      elsif current_invitation_status.errored_importing_starter_code?
        GitHubClassroom.statsd.increment("v2_exercise_repo.import.retry")
      end
      current_invitation_status.waiting!
      AssignmentRepo::CreateGitHubRepositoryJob.perform_later(current_assignment, current_user)
      job_started = true
    end
    render json: {
      job_started: job_started,
      status: current_invitation_status.status
    }
  end
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize

  def progress
    render json: { status: current_invitation_status.status }
  end

  def show; end

  def success; end

  def join_roster
    super

    redirect_to assignment_invitation_url(current_invitation)
  rescue ActiveRecord::ActiveRecordError
    flash[:error] = "An error occured, please try again!"
  end

  private

  # rubocop:disable MethodLength
  def ensure_submission_repository_exists
    return not_found unless current_assignment_repo
    return if current_assignment_repo
              .github_repository
              .present?(headers: GitHub::APIHeaders.no_cache_no_store)

    current_assignment_repo.destroy
    remove_instance_variable(:@current_assignment_repo)

    if import_resiliency_enabled?
      redirect_to setupv2_assignment_invitation_path
    else
      create_submission
    end
  end
  # rubocop:enable MethodLength

  def check_user_not_previous_acceptee
    return if import_resiliency_enabled?
    return if current_assignment_repo.nil?
    redirect_to success_assignment_invitation_path
  end

  # rubocop:disable AbcSize
  # rubocop:disable CyclomaticComplexity
  # rubocop:disable MethodLength
  def route_based_on_status
    return unless import_resiliency_enabled?
    case current_invitation_status.status
    when "unaccepted"
      redirect_to assignment_invitation_path(current_invitation) if action_name != "show"
    when "completed"
      redirect_to success_assignment_invitation_path if action_name != "success"
    when *(InviteStatus::ERRORED_STATUSES + InviteStatus::SETUP_STATUSES)
      redirect_to setupv2_assignment_invitation_path if action_name != "setupv2"
    else
      raise InvalidStatusForRouteError, "No route registered for status: #{current_invitation_status.status}"
    end
  end
  # rubocop:enable AbcSize
  # rubocop:enable CyclomaticComplexity
  # rubocop:enable MethodLength

  def ensure_import_resiliency_enabled
    render status: 404, json: { error: "Not found" } unless import_resiliency_enabled?
  end

  def create_submission
    result = current_invitation.redeem_for(current_user)

    if result.success?
      yield if block_given?
    else
      GitHubClassroom.statsd.increment("exercise_invitation.fail")

      flash[:error] = result.error
      redirect_to assignment_invitation_path(current_invitation)
    end
  end

  def current_assignment_repo
    @current_assignment_repo ||= AssignmentRepo.find_by(assignment: current_assignment, user: current_user)
  end

  def current_invitation
    @current_invitation ||= AssignmentInvitation.find_by!(key: params[:id])
  end

  def current_invitation_status
    @current_invitation_status ||= current_invitation.status(current_user)
  end

  def required_scopes
    GitHubClassroom::Scopes::ASSIGNMENT_STUDENT
  end
end
