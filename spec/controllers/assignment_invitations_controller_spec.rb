require 'rails_helper'

RSpec.describe AssignmentInvitationsController, type: :controller do
  describe 'GET #show', :vcr do
    let(:invitation) { create(:assignment_invitation) }

    context 'unauthenticated request' do
      it 'redirects the new user to sign in with GitHub' do
        get :show, id: invitation.key
        expect(response).to redirect_to(login_path)
      end
    end

    context 'authenticated request' do
      let(:user) { GitHubFactory.create_classroom_student }

      before(:each) do
        sign_in(user)
      end

      it 'will bring you to the page' do
        get :show, id: invitation.key
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH #accept_invitation', :vcr do
    let(:organization) { GitHubFactory.create_owner_classroom_org }
    let(:user)         { GitHubFactory.create_classroom_student   }

    let(:assignment) do
      Assignment.create(creator: organization.users.first,
                        title: 'ruby-project',
                        starter_code_repo_id: '1062897',
                        organization: organization,
                        public_repo: false)
    end

    let(:invitation) { AssignmentInvitation.create(assignment: assignment) }

    before(:each) do
      request.env['HTTP_REFERER'] = "http://classroomtest.com/group-assignment-invitations/#{invitation.key}"
      sign_in(user)
    end

    after(:each) do
      AssignmentRepo.destroy_all
    end

    it 'redeems the users invitation' do
      patch :accept_invitation, id: invitation.key
      expect(user.assignment_repos.count).to eql(1)
    end

    context 'github repository creation fails' do
      before do
        allow_any_instance_of(AssignmentRepo)
          .to receive(:create_github_repository)
          .and_raise(GitHub::Error)
      end

      it 'does not create a an assignment repo record' do
        patch :accept_invitation, id: invitation.key

        expect(assignment.assignment_repos.count).to eq(0)
      end
    end

    context 'github repository already exists' do
      let(:assignment_repo) { AssignmentRepo.new(assignment: assignment, user: user) }

      before do
        assignment_repo.create_github_repository
      end

      it 'redeems the users invitation' do
        patch :accept_invitation, id: invitation.key
        expect(user.assignment_repos.count).to eql(1)
      end

      it 'adds the user as a collaborator to the assignment repo' do
        patch :accept_invitation, id: invitation.key
        adding_collaborator_regex = %r{\A#{github_url('/repositories')}/\d+/collaborators/#{user.decorate.login}\z}
        expect(WebMock).to have_requested(:put, adding_collaborator_regex)
      end

      it 'creates a new assignment repo with a suffixed repo name' do
        repo_name_suffix = 'new'
        patch :accept_invitation, id: invitation.key, repo_name_suffix: repo_name_suffix
        expect(WebMock).to have_requested(:get, github_url("/repos/#{classroom_owner_organization_github_login}"\
                                                           "/#{assignment_repo.repo_name}-#{repo_name_suffix}"))
        expect(user.assignment_repos.count).to eql(1)
      end

      after(:each) do
        assignment_repo.destroy_github_repository
      end
    end

    context 'github import fails' do
      before do
        allow_any_instance_of(GitHubRepository)
          .to receive(:get_starter_code_from)
          .and_raise(GitHub::Error)
      end

      it 'removes the repository on GitHub' do
        patch :accept_invitation, id: invitation.key
        expect(WebMock).to have_requested(:delete, %r{\A#{github_url('/repositories')}/\d+\z})
      end
    end
  end
end
