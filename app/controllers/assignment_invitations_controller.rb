# frozen_string_literal: true

# rubocop:disable ClassLength
class AssignmentInvitationsController < ApplicationController
  include InvitationsControllerMethods
  include RepoSetup

  before_action :check_user_not_previous_acceptee, :check_should_redirect_to_roster_page, only: [:show]
  before_action :ensure_submission_repository_exists, only: %i[setup setup_progress success]
  before_action :ensure_authorized_repo_setup, only: %i[setup setup_progress]

  # rubocop:disable PerceivedComplexity
  # rubocop:disable MethodLength
  # rubocop:disable AbcSize
  # rubocop:disable CyclomaticComplexity
  def accept
    if import_resiliency_enabled?
      result = current_invitation.redeem_for(current_user, import_resiliency: import_resiliency_enabled?)
      case result.status
      when :success
        GitHubClassroom.statsd.increment("exercise_invitation.accept")
        if current_submission.starter_code_repo_id
          redirect_to setup_assignment_invitation_path
        else
          current_invitation.completed!
          redirect_to success_assignment_invitation_path
        end
      when :pending
        GitHubClassroom.statsd.increment("exercise_invitation.accept")
        redirect_to setupv2_assignment_invitation_path
      when :error
        GitHubClassroom.statsd.increment("exercise_invitation.fail")
        current_invitation.errored!

        flash[:error] = result.error
        redirect_to assignment_invitation_path(current_invitation)
      end
    else
      create_submission do
        GitHubClassroom.statsd.increment("exercise_invitation.accept")
        if current_submission.starter_code_repo_id
          redirect_to setup_assignment_invitation_path
        else
          redirect_to success_assignment_invitation_path
        end
      end
    end
  end
  # rubocop:enable PerceivedComplexity
  # rubocop:enable MethodLength
  # rubocop:enable AbcSize
  # rubocop:enable CyclomaticComplexity

  def setup; end

  def setupv2
    render status: 404 unless import_resiliency_enabled?
  end

  # rubocop:disable MethodLength
  def create
    if import_resiliency_enabled?
      job_started = false
      if current_invitation.accepted? || current_invitation.errored?
        AssignmentRepo::CreateGitHubRepositoryJob.perform_later(current_assignment, current_user)
        job_started = true
      end
      render json: {
        job_started: job_started
      }
    else
      render status: 404, json: {}
    end
  end
  # rubocop:enable MethodLength

  def progress
    if import_resiliency_enabled?
      render json: { status: current_invitation.status }
    else
      render status: 404, json: {}
    end
  end

  def setup_progress
    perform_setup(current_submission, classroom_config) if configurable_submission?

    render json: setup_status(current_submission)
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
    if repo_setup_enabled? && setup_status(current_submission)[:status] != :complete
      return redirect_to setup_assignment_invitation_path
    end
    redirect_to success_assignment_invitation_path
  end

  def ensure_authorized_repo_setup
    redirect_to success_assignment_invitation_path unless repo_setup_enabled?
  end

  def classroom_config
    starter_code_repo_id = current_submission.starter_code_repo_id
    client               = current_submission.creator.github_client

    starter_repo         = GitHubRepository.new(client, starter_code_repo_id)
    ClassroomConfig.new(starter_repo)
  end

  def configurable_submission?
    repo             = current_submission.github_repository
    classroom_branch = repo.branch_present? config_branch
    repo.imported? && classroom_branch && current_submission.not_configured?
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
# rubocop:enable ClassLength
