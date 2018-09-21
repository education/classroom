# frozen_string_literal: true

class GroupAssignmentInvitation < ApplicationRecord
  include ShortKey

  default_scope { where(deleted_at: nil) }

  update_index("stafftools#group_assignment_invitation") { self }

  belongs_to :group_assignment

  has_one :grouping,     through: :group_assignment
  has_one :organization, through: :group_assignment

  has_many :groups, through: :grouping
  has_many :group_invite_statuses, dependent: :destroy

  validates :group_assignment, presence: true

  validates :key, presence:   true
  validates :key, uniqueness: true

  validates :short_key, uniqueness: true, allow_nil: true

  after_initialize :assign_key

  delegate :title, to: :group_assignment

  def redeem_for(invitee, selected_group = nil, new_group_title = nil, group_import_resiliency: false)
    return Result.failed("Invitations for this assignment have been disabled.") unless enabled?

    repo_access    = RepoAccess.find_or_create_by!(user: invitee, organization: organization)
    invitees_group = group(repo_access, selected_group, new_group_title)

    invitees_group.repo_accesses << repo_access unless invitees_group.repo_accesses.include?(repo_access)

    group_assignment_repo(invitees_group, group_import_resiliency)
  end

  def to_param
    key
  end

  def enabled?
    group_assignment.invitations_enabled?
  end

  def status(group)
    group_invite_status = group_invite_statuses.find_by(group: group)
    return group_invite_status if group_invite_status.present?

    GroupInviteStatus.create(group: group, group_assignment_invitation: self)
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end

  private

  def group(repo_access, selected_group, selected_group_title)
    group = Group.joins(:repo_accesses).find_by(grouping: grouping, repo_accesses: { id: repo_access.id })

    return group if group.present?
    return selected_group if selected_group

    Group.create(title: selected_group_title, grouping: grouping)
  end

  # rubocop:disable MethodLength
  def group_assignment_repo(invitees_group, group_import_resiliency)
    group_assignment_params = { group_assignment: group_assignment, group: invitees_group }
    repo                    = GroupAssignmentRepo.find_by(group_assignment_params)

    return Result.success(repo) if repo

    if group_import_resiliency
      invite_status = status(invitees_group)
      invite_status.accepted! if invite_status.unaccepted?
      return Result.pending
    else
      repo = GroupAssignmentRepo.create(group_assignment_params)
      return Result.success(repo) if repo
      Result.failed("An error has occurred, please refresh the page and try again.")
    end
  end
  # rubocop:enable MethodLength
end
