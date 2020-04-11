# frozen_string_literal: true

class CreateGitHubRepoService
  class Exercise
    def self.build(assignment, collaborator)
      if collaborator.is_a?(User)
        IndividualExercise.new(assignment, collaborator)
      else
        GroupExercise.new(assignment, collaborator)
      end
    end

    attr_reader :assignment, :collaborator, :organization, :invite_status, :github_organization
    delegate :status, to: :invite_status
    delegate :use_template_repos?, to: :assignment

    def initialize(assignment, collaborator)
      @assignment = assignment
      @collaborator = collaborator
      @organization = assignment.organization
      @invite_status = assignment.invitation.status(collaborator)
      @github_organization = github_organization_with_access
    end

    def repo_name
      @repo_name ||= generate_repo_name
    end

    def default_repo_name
      "#{assignment.slug}-#{slug}"
    end

    def organization_login
      @organization_login ||= @github_organization.login
    end

    def assignment_type
      assignment.class.to_s.underscore
    end

    def user?
      is_a?(IndividualExercise)
    end

    def admin?
      assignment.students_are_repo_admins?
    end

    private

    def generate_repo_name
      suffix_count = 0

      loop do
        name = "#{organization_login}/#{suffixed_repo_name(suffix_count)}"
        break unless GitHubRepository.present?(organization.github_client, name)

        suffix_count += 1
      end

      suffixed_repo_name(suffix_count)
    end

    def suffixed_repo_name(suffix_count)
      return default_repo_name if suffix_count.zero?

      suffix = "-#{suffix_count}"
      default_repo_name.truncate(100 - suffix.length, omission: "") + suffix
    end

    def github_organization_with_access
      github_organization_with_random_token = @organization.github_organization
      return github_organization_with_random_token unless assignment.starter_code?

      GitHub::Errors.with_error_handling do
        github_organization_with_random_token.client.repository(assignment.starter_code_repo_id)
      end

      github_organization_with_random_token
    rescue GitHub::NotFound
      github_client = assignment.creator.github_client
      GitHubOrganization.new(github_client, assignment.starter_code_repo_id)
    end
  end
end
