# frozen_string_literal: true

class GraphqlAssignmentsController < ApplicationController
  include OrganizationAuthorization
  include StarterCode

  before_action :set_assignment, except: %i[new create]
  before_action :verify_authorized

  def new
    @assignment = Assignment.new
    render 'assignments/new'
  end

  def create
    @assignment = Assignment.new(new_assignment_params)
    @assignment.build_assignment_invitation

    if @assignment.save
      flash[:success] = "\"#{@assignment.title}\" has been created!"
      redirect_to organization_assignment_path(@organization, @assignment)
    else
      render 'assignments/new'
    end
  end

  def show
    @assignment_repos = AssignmentRepo.where(assignment: @assignment).page(params[:page])
    render 'assignments/show'
  end

  def edit
    render 'assignments/edit'
  end

  def update
    result = Assignment::Editor.perform(assignment: @assignment, options: update_assignment_params.to_h)
    if result.success?
      flash[:success] = "Assignment \"#{@assignment.title}\" is being updated"
      redirect_to organization_assignment_path(@organization, @assignment)
    else
      @assignment.reload if @assignment.slug.blank?
      render 'assignments/edit'
    end
  end

  def destroy
    if @assignment.update_attributes(deleted_at: Time.zone.now)
      DestroyResourceJob.perform_later(@assignment)
      flash[:success] = "\"#{@assignment.title}\" is being deleted"
      redirect_to @organization
    else
      render 'assignments/edit'
    end
  end

  private

  def student_identifier_types
    @student_identifier_types ||= @organization.student_identifier_types.select(:name, :id).map do |student_identifier|
      [student_identifier.name, student_identifier.id]
    end
  end
  helper_method :student_identifier_types

  def new_assignment_params
    params
      .require(:assignment)
      .permit(:title, :slug, :public_repo, :students_are_repo_admins)
      .merge(creator: current_user,
             organization: @organization,
             starter_code_repo_id: starter_code_repo_id_param,
             student_identifier_type: student_identifier_type_param)
  end

  def set_assignment
    @assignment = @organization.assignments.includes(:assignment_invitation).find_by!(slug: params[:id])
  end

  def starter_code_repo_id_param
    if params[:repo_id].present?
      validate_starter_code_repository_id(params[:repo_id])
    else
      starter_code_repository_id(params[:repo_name])
    end
  end

  def student_identifier_type_param
    return unless params.key?(:student_identifier_type)
    StudentIdentifierType.find_by(id: student_identifier_type_params[:id], organization: @organization)
  end

  def update_assignment_params
    params
      .require(:assignment)
      .permit(:title, :slug, :public_repo, :students_are_repo_admins)
      .merge(starter_code_repo_id: starter_code_repo_id_param, student_identifier_type: student_identifier_type_param)
  end

  def student_identifier_type_params
    params
      .require(:student_identifier_type)
      .permit(:id)
  end

  def verify_authorized
    return if current_user&.staff? && graphql_enabled?

    not_found
  end
end
