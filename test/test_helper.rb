ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: ENV["CI"] ? 1 : :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def grant_membership_to(member, start_date: 1.month.ago)
      membership_product = products(:annual_membership)
      staff_user = users(:staff)

      # Creiamo la vendita che genera la sottoscrizione
      Sale.create!(
        member: member,
        user: staff_user,
        product: membership_product,
        sold_on: start_date,
        amount_cents: 3000,
        payment_method: :cash,
        # SubscriptionIssuer creerà la subscription automaticamente
        subscription_attributes: {
          member: member,
          product: membership_product
          # Le date vengono calcolate automaticamente (Duration)
        }
      )
    end
  end
end
