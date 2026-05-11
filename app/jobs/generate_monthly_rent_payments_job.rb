# Ensures every active lease has a pending RentPayment row for each
# of the next MONTHS_AHEAD months. Designed to run on the 1st of each
# month (sidekiq-cron schedule TBD).
#
# Idempotent: RentPayment.generate_for_lease uses find_or_create_by
# on (lease_id, due_date), so running this job repeatedly does not
# duplicate rows.
class GenerateMonthlyRentPaymentsJob < ApplicationJob
  queue_as :default

  MONTHS_AHEAD = 3

  def perform
    Lease.active.find_each do |lease|
      RentPayment.generate_for_lease(lease: lease, months: MONTHS_AHEAD)
    end
  end
end
