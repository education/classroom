# frozen_string_literal: true
namespace :users do
  desc "Find all teachers that don't have the correct scopes"
  task find_deficient_organization_scopes: :environment do
    results = []

    OrganizationsUser.all.each do |organizations_user|
      organization = organizations_user.organization
      user         = organizations_user.user

      next if results[organization.id].present?
      next if (Classroom::Scopes::TEACHER - user.github_client_scopes).empty?

      results << { organization_id: organization.id, user_id: user.id }
    end

    puts results if results.present?
    puts 'Happy day!! All the scopes are good to go!'
  end
end
