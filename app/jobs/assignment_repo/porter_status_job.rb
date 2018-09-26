# frozen_string_literal: true

class AssignmentRepo
  class PorterStatusJob < ApplicationJob
    REPO_IMPORT_STEPS = GitHubRepository::IMPORT_STEPS
    WAIT_TIME = 10.seconds
    queue_as :porter_status

    # rubocop:disable MethodLength
    # rubocop:disable AbcSize
    # rubocop:disable CyclomaticComplexity
    def perform(assignment_repo, user)
      github_repository = assignment_repo.github_repository

      invite_status = assignment_repo.assignment.invitation.status(user)

      begin
        last_progress = nil
        # rubocop:disable BlockLength
        result = Octopoller.poll(wait: WAIT_TIME, retries: 3) do
          begin
            GitHubClassroom.statsd.increment("v2_exercise_repo.import.poll")
            progress = github_repository.import_progress
            case progress[:status]
            when GitHubRepository::IMPORT_COMPLETE
              Creator::REPOSITORY_CREATION_COMPLETE
            when *GitHubRepository::IMPORT_ERRORS
              Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
            when *GitHubRepository::IMPORT_ONGOING
              if last_progress != progress[:status]
                ActionCable.server.broadcast(
                  RepositoryCreationStatusChannel.channel(user_id: user.id),
                  status: invite_status.status,
                  text: AssignmentRepo::Creator::IMPORT_ONGOING,
                  percent: ((REPO_IMPORT_STEPS.index(progress[:status]) + 1) * 100) / REPO_IMPORT_STEPS.count,
                  status_text: progress[:status_text],
                  repo_url: github_repository.html_url
                )
                last_progress = progress[:status]
              end
              :re_poll
            end
          rescue GitHub::Error => error
            logger.warn error.to_s
            Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
          end
        end
        # rubocop:enable BlockLength

        case result
        when Creator::REPOSITORY_STARTER_CODE_IMPORT_FAILED
          invite_status.errored_importing_starter_code!
          ActionCable.server.broadcast(
            RepositoryCreationStatusChannel.channel(user_id: user.id),
            error: result,
            status: invite_status.status
          )
          logger.warn result.to_s
          GitHubClassroom.statsd.increment("v2_exercise_repo.import.fail")
          assignment_repo.destroy
        when Creator::REPOSITORY_CREATION_COMPLETE
          invite_status.completed!
          ActionCable.server.broadcast(
            RepositoryCreationStatusChannel.channel(user_id: user.id),
            text: result,
            status: invite_status.status,
            percent: 100,
            status_text: "Done",
            repo_url: github_repository.html_url
          )
          GitHubClassroom.statsd.increment("v2_exercise_repo.import.success")
        end
      rescue Octopoller::TooManyAttemptsError
        GitHubClassroom.statsd.increment("v2_exercise_repo.import.timeout")
        PorterStatusJob.perform_later(assignment_repo, user)
      end
    end
    # rubocop:enable MethodLength
    # rubocop:enable AbcSize
    # rubocop:enable CyclomaticComplexity
  end
end
